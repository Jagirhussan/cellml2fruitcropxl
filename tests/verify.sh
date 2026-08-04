#!/usr/bin/env bash
# Clean-clone generation, compilation, and numerical smoke test.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
PY="${PYTHON:-python}"
JAR="${COMMONS_MATH_JAR:-/usr/share/java/commons-math3.jar}"
GEN="${REPO_ROOT}/build/apptainer-smoke"
PKG="org.fruitcropxl.cellml"
PKG_PATH="org/fruitcropxl/cellml"
JAVA_DIR="${GEN}/${PKG_PATH}"
CLASSES="${GEN}/classes"
SIMPLE_MODEL="${REPO_ROOT}/cellml/jfruit2_oracle.cellml"
EBM_MODEL="${REPO_ROOT}/cellml/Fruit_Sugar_EBM.cellml"
NUMERIC_OUTPUT="${GEN}/standalone.csv"

for fixture in "${SIMPLE_MODEL}" "${EBM_MODEL}"; do
    if [[ ! -r "${fixture}" ]]; then
        echo "ERROR: repository fixture is missing: ${fixture}" >&2
        exit 1
    fi
done
if [[ ! -r "${JAR}" ]]; then
    echo "ERROR: Apache Commons Math JAR is missing: ${JAR}" >&2
    echo "Install Ubuntu package libcommons-math3-java or set COMMONS_MATH_JAR." >&2
    exit 1
fi
if ! command -v "${PY}" >/dev/null 2>&1; then
    echo "ERROR: Python command is unavailable: ${PY}" >&2
    exit 1
fi
if ! command -v javac >/dev/null 2>&1 || ! command -v java >/dev/null 2>&1; then
    echo "ERROR: java and javac are required." >&2
    exit 1
fi

export PYTHONPATH="${REPO_ROOT}/src${PYTHONPATH:+:${PYTHONPATH}}"

rm -rf "${GEN}"
mkdir -p "${GEN}" "${CLASSES}"

echo "== Generate repository CellML fixtures =="
"${PY}" -m cellml2fruitcropxl.cli \
    --cellml "${SIMPLE_MODEL}" \
    --package "${PKG}" \
    --output-dir "${GEN}" \
    --with-fruit-service \
    --force
"${PY}" -m cellml2fruitcropxl.cli \
    --cellml "${EBM_MODEL}" \
    --package "${PKG}" \
    --output-dir "${GEN}" \
    --force

echo "== Verify generated sources =="
expected_files=(
    AbstractCellmlModel.java
    Jfruit2Oracle.java
    Jfruit2OracleFruitService.java
    Model.java
    FruitServiceAPI.java
    SugarEbmSuperset.java
)
for filename in "${expected_files[@]}"; do
    test -s "${JAVA_DIR}/${filename}" || {
        echo "ERROR: expected generated file is missing or empty: ${filename}" >&2
        exit 1
    }
done

grep -Fq "public double mSuc" "${JAVA_DIR}/Jfruit2Oracle.java"
grep -Fq "public double q_total_vol" "${JAVA_DIR}/SugarEbmSuperset.java"
grep -Fq "abstract class Jfruit2Oracle" "${JAVA_DIR}/Jfruit2Oracle.java"
grep -Fq "abstract class SugarEbmSuperset" "${JAVA_DIR}/SugarEbmSuperset.java"
grep -Fq " ? " "${JAVA_DIR}/SugarEbmSuperset.java"

for generated_model in \
    "${JAVA_DIR}/Jfruit2Oracle.java" \
    "${JAVA_DIR}/SugarEbmSuperset.java"; do
    if grep -Eq '(variables|constants|computed_constants|algebraic_variables|external_variables)\[' \
        "${generated_model}"; then
        echo "ERROR: raw libcellml array expression remains in ${generated_model}" >&2
        exit 1
    fi
    if grep -Fq "TODO" "${generated_model}"; then
        echo "ERROR: silent TODO output remains in ${generated_model}" >&2
        exit 1
    fi
done

echo "== Compile generated Java with system Commons Math =="
javac \
    -d "${CLASSES}" \
    -cp "${JAR}" \
    "${JAVA_DIR}"/*.java \
    "${REPO_ROOT}/examples/Jfruit2OracleSim.java" \
    "${REPO_ROOT}/examples/StandaloneExample.java" \
    "${REPO_ROOT}/examples/ServiceExample.java"

echo "== Run numerical smoke simulation =="
java \
    -cp "${CLASSES}:${JAR}" \
    org.fruitcropxl.cellml.StandaloneExample \
    > "${NUMERIC_OUTPUT}"

if [[ "$(wc -l < "${NUMERIC_OUTPUT}")" -lt 2 ]]; then
    echo "ERROR: numerical smoke test produced no data rows." >&2
    exit 1
fi
if grep -Eiq '(^|,)(nan|[-+]?infinity)(,|$)' "${NUMERIC_OUTPUT}"; then
    echo "ERROR: numerical smoke test produced NaN or infinity." >&2
    exit 1
fi

echo "Smoke test passed."
echo "Generated sources and outputs: ${GEN}"
