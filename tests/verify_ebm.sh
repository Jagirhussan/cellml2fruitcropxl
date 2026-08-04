#!/usr/bin/env bash
# Extended EBM comparison. External numerical fixtures are explicit and required.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
PY="${PYTHON:-python}"
JAR="${COMMONS_MATH_JAR:-/usr/share/java/commons-math3.jar}"
OUTPUT_ROOT="${EBM_OUTPUT_DIR:-${REPO_ROOT}/build/ebm}"
ATOL="${EBM_ATOL:-1e-6}"
RTOL="${EBM_RTOL:-1e-3}"

missing=()
if [[ -z "${EBM_TARGET_CSV:-}" || ! -r "${EBM_TARGET_CSV:-}" ]]; then
    missing+=("EBM_TARGET_CSV: target growth/sugar CSV")
fi
if [[ -z "${EBM_CLIMATE_CSV:-}" || ! -r "${EBM_CLIMATE_CSV:-}" ]]; then
    missing+=("EBM_CLIMATE_CSV: climate CSV with VPD_Pa and Psi_stem_Pa")
fi
if [[ -z "${EBM_PYTHON_REFERENCE_CSV:-}" || ! -r "${EBM_PYTHON_REFERENCE_CSV:-}" ]]; then
    missing+=("EBM_PYTHON_REFERENCE_CSV: precomputed Python/Radau reference CSV")
fi

if ((${#missing[@]})); then
    echo "ERROR: extended EBM validation requires external numerical fixtures." >&2
    echo "Set each variable to a readable file:" >&2
    for item in "${missing[@]}"; do
        echo "  - ${item}" >&2
    done
    echo "This test did not run and has not been reported as passed." >&2
    exit 2
fi
if [[ ! -r "${JAR}" ]]; then
    echo "ERROR: Apache Commons Math JAR is missing: ${JAR}" >&2
    exit 1
fi

mkdir -p "${OUTPUT_ROOT}"
RUN_DIR="$(mktemp -d "${OUTPUT_ROOT}/run.XXXXXX")"
INPUT_DIR="${RUN_DIR}/input"
GEN="${RUN_DIR}/generated"
CLASSES="${RUN_DIR}/classes"
PKG_PATH="org/fruitcropxl/cellml"
JAVA_OUTPUT="${RUN_DIR}/ebm_java.csv"
PLOT_OUTPUT="${RUN_DIR}/ebm_comparison.png"
mkdir -p "${INPUT_DIR}" "${GEN}" "${CLASSES}"

# SugarEbmSupersetSim expects these two fixed basenames within one input directory.
cp -- "${EBM_TARGET_CSV}" \
    "${INPUT_DIR}/growth_r1_fw0.50_dm0.50_sugar_sorbitol_r1_2021_day34_mean_out.csv"
cp -- "${EBM_CLIMATE_CSV}" "${INPUT_DIR}/climate_oracle.csv"

export PYTHONPATH="${REPO_ROOT}/src${PYTHONPATH:+:${PYTHONPATH}}"

echo "== Generate and compile the extended EBM model =="
"${PY}" -m cellml2fruitcropxl.cli \
    --cellml "${REPO_ROOT}/cellml/Fruit_Sugar_EBM.cellml" \
    --package org.fruitcropxl.cellml \
    --output-dir "${GEN}" \
    --force

javac \
    -d "${CLASSES}" \
    -cp "${JAR}" \
    "${GEN}/${PKG_PATH}/AbstractCellmlModel.java" \
    "${GEN}/${PKG_PATH}/SugarEbmSuperset.java" \
    "${REPO_ROOT}/examples/SugarEbmSupersetSim.java" \
    "${REPO_ROOT}/examples/EBMExample.java"

echo "== Run Java EBM simulation =="
java \
    -cp "${CLASSES}:${JAR}" \
    org.fruitcropxl.cellml.EBMExample \
    "${INPUT_DIR}" \
    > "${JAVA_OUTPUT}"

echo "== Compare against Python/Radau reference =="
"${PY}" - \
    "${EBM_PYTHON_REFERENCE_CSV}" \
    "${JAVA_OUTPUT}" \
    "${PLOT_OUTPUT}" \
    "${ATOL}" \
    "${RTOL}" <<'PYTHON'
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

reference_path, java_path, plot_path, atol_text, rtol_text = sys.argv[1:]
atol = float(atol_text)
rtol = float(rtol_text)
reference = pd.read_csv(reference_path)
java = pd.read_csv(java_path)

if reference.empty or java.empty:
    raise SystemExit("ERROR: reference or Java output contains no data rows")
if len(reference) != len(java):
    raise SystemExit(
        f"ERROR: row count differs: reference={len(reference)}, Java={len(java)}"
    )

common = [column for column in reference.columns if column in java.columns]
if not common:
    raise SystemExit("ERROR: reference and Java output have no common columns")

failures = []
for column in common:
    ref_values = pd.to_numeric(reference[column], errors="coerce").to_numpy(float)
    java_values = pd.to_numeric(java[column], errors="coerce").to_numpy(float)
    if not np.isfinite(ref_values).all():
        failures.append(f"{column}: reference contains NaN or infinity")
        continue
    if not np.isfinite(java_values).all():
        failures.append(f"{column}: Java contains NaN or infinity")
        continue
    error = np.abs(java_values - ref_values)
    limit = atol + rtol * np.abs(ref_values)
    bad = error > limit
    if bad.any():
        failures.append(
            f"{column}: {bad.sum()} values exceed tolerance; "
            f"max_abs_error={error.max():.6e}"
        )

plot_columns = [column for column in common if column.lower() not in {"tdays", "time", "t"}]
if plot_columns:
    columns = plot_columns[:6]
    fig, axes = plt.subplots(2, 3, figsize=(16, 9), squeeze=False)
    x = np.arange(len(reference))
    for axis, column in zip(axes.flat, columns):
        axis.plot(x, reference[column], label="Python/Radau")
        axis.plot(x, java[column], "--", label="Java")
        axis.set_title(column)
        axis.grid(alpha=0.3)
        axis.legend(fontsize=8)
    for axis in axes.flat[len(columns):]:
        axis.set_visible(False)
    fig.tight_layout()
    fig.savefig(plot_path, dpi=150)

if failures:
    print(f"Tolerance: atol={atol:g}, rtol={rtol:g}", file=sys.stderr)
    for failure in failures:
        print(f"ERROR: {failure}", file=sys.stderr)
    raise SystemExit(1)

print(f"Compared {len(common)} columns at atol={atol:g}, rtol={rtol:g}: OK")
print(f"Plot: {plot_path}")
PYTHON

echo "Extended EBM validation passed."
echo "Outputs: ${RUN_DIR}"
