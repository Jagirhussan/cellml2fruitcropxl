#!/usr/bin/env bash
# verify_ebm.sh — Full verification of Fruit_Sugar_EBM model.
#
# 1. Create climate CSV if missing
# 2. Run Python Radau reference (if not already done)
# 3. Regenerate Java from CellML via cellml2fruitcropxl
# 4. Compile and run Java simulation
# 5. Compare Java vs Python, plot both
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$ROOT/../.." && pwd)"
# Point to the python environment that has libcellml installed
PY="/usr/bin/python"
JAR="$WORKSPACE/fruitcropmodel-master/ext/ext_linux/jfruit2-1.3.6-jar-with-dependencies.jar"
GEN="$ROOT/gen"
OUT="$ROOT/../../../_sugar2_refactor/out"
PKG_PATH="org/fruitcropxl/cellml"

cd "$WORKSPACE"

# 1. Create climate CSV if missing
if [ ! -f climate_oracle.csv ]; then
    echo ">> Creating climate_oracle.csv..."
    $PY create_climate_csv.py
fi

# 2. Run Python Radau reference (if not already done)
if [ ! -f "$OUT/ebm_python_radau.csv" ]; then
    echo ">> Running Python Radau reference..."
    $PY _sugar2_refactor/ebm_radau_reference.py > "$OUT/ebm_python_radau.csv" 2> "$OUT/ebm_python_radau.stderr"
    cat "$OUT/ebm_python_radau.stderr"
fi

# 3. Regenerate Java from CellML
echo ">> Generating Java from Fruit_Sugar_EBM.cellml..."
export PYTHONPATH="$ROOT/../src:${PYTHONPATH:-}"
$PY -m cellml2fruitcropxl.cli --cellml "$WORKSPACE/Fruit_Sugar_EBM.cellml" \
    --package org.fruitcropxl.cellml --output-dir "$GEN" 2>&1 | tail -3

# 4. Compile and run Java
echo ">> Compiling Java..."
javac -d "$GEN/out" -cp "$JAR" \
    "$GEN/$PKG_PATH/AbstractCellmlModel.java" \
    "$GEN/$PKG_PATH/SugarEbmSuperset.java" \
    "$ROOT/examples/SugarEbmSupersetSim.java" \
    "$ROOT/examples/EBMExample.java" 2>&1

echo ">> Running Java EBMExample..."
java -cp "$GEN/out:$JAR" org.fruitcropxl.cellml.EBMExample "$WORKSPACE" \
    > "$OUT/ebm_java.csv" 2> "$OUT/ebm_java.stderr"
echo "=== Java stderr (head) ==="
head -10 "$OUT/ebm_java.stderr"
echo "=== Java CSV lines ==="
wc -l "$OUT/ebm_java.csv"

# 5. Compare and plot
echo ">> Comparing and plotting..."
$PY - "$OUT/ebm_python_radau.csv" "$OUT/ebm_java.csv" "$ROOT/ebm_comparison.png" << 'PYTHON_SCRIPT'
import sys, os
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

py_file = sys.argv[1]
java_file = sys.argv[2]
plot_file = sys.argv[3]

def load_csv(path):
    with open(path) as f:
        lines = f.readlines()
    header = lines[0].strip().split(',')
    data = []
    for line in lines[1:]:
        parts = line.strip().split(',')
        if len(parts) < 2: continue
        try:
            row = [float(x) for x in parts]
            data.append(row)
        except ValueError:
            continue
    return header, np.array(data)

py_header, py_data = load_csv(py_file)
java_header, java_data = load_csv(java_file)

print(f"Python: {len(py_data)} rows, Java: {len(java_data)} rows")
print(f"Python header: {py_header}")
print(f"Java header: {java_header}")

# Find common state columns (by name)
# Python header: tDays, q_total_vol, q_v_fru, q_c_fru, q_p_glu, q_v_glu, q_c_glu, q_c_sor, q_v_suc, q_c_suc, q_p_vol, q_p_sta
# Java header should be the same
n_states = min(len(py_header) - 1, len(java_header) - 1, 11)

# Compute totals for comparison
def compute_totals(data):
    # state order: [0]=q_total_vol, [1]=q_v_fru, [2]=q_c_fru, [3]=q_p_glu,
    #   [4]=q_v_glu, [5]=q_c_glu, [6]=q_c_sor, [7]=q_v_suc, [8]=q_c_suc, [9]=q_p_vol, [10]=q_p_sta
    return {
        'Total_Suc': data[:, 8] + data[:, 7],   # q_c_suc + q_v_suc
        'Total_Sor': data[:, 6],                 # q_c_sor
        'Total_Glu': data[:, 5] + data[:, 4] + data[:, 3],  # q_c_glu + q_v_glu + q_p_glu
        'Total_Fru': data[:, 2] + data[:, 1],    # q_c_fru + q_v_fru
        'Total_Sta': data[:, 10],                # q_p_sta
        'V_total': data[:, 0] * 1e6,             # q_total_vol * 1e6
    }

py_totals = compute_totals(py_data)
java_totals = compute_totals(java_data)

# Plot comparison
fig, axes = plt.subplots(2, 3, figsize=(18, 10))
fig.suptitle('Fruit_Sugar_EBM: Python Radau vs Java DormandPrince54', fontsize=14)

py_t = py_data[:, 0]
java_t = java_data[:, 0]

for ax, (name, py_vals) in zip(axes.flatten(), py_totals.items()):
    java_vals = java_totals.get(name, np.full(len(java_t), np.nan))
    ax.plot(py_t, py_vals, 'r-', lw=1.5, label='Python Radau')
    ax.plot(java_t, java_vals, 'b--', lw=1.5, label='Java DP54')
    ax.set_title(name)
    ax.legend(fontsize=8)
    ax.grid(True, alpha=0.3)
    
    # Check for NaN/divergence in Java
    nan_count = np.sum(np.isnan(java_vals))
    if nan_count > 0:
        ax.set_title(f'{name} (Java: {nan_count} NaN!)', color='red')

plt.tight_layout()
plt.savefig(plot_file, dpi=150)
print(f"Plot saved to {plot_file}")

# Print max errors (excluding NaN)
print("\n--- Max Absolute Errors (excluding NaN) ---")
for name in py_totals:
    py_vals = py_totals[name]
    java_vals = java_totals.get(name, np.full(len(java_t), np.nan))
    mask = ~np.isnan(java_vals) & ~np.isnan(py_vals)
    if np.sum(mask) > 0:
        max_err = np.max(np.abs(py_vals[mask] - java_vals[mask]))
        print(f"  {name:12}: max_err = {max_err:.6e} ({np.sum(mask)} valid points)")
    else:
        print(f"  {name:12}: ALL NaN (Java diverged)")
PYTHON_SCRIPT

echo ""
echo "=== DONE ==="
echo "Comparison plot: $ROOT/ebm_comparison.png"
echo "Python reference: $OUT/ebm_python_radau.csv"
echo "Java output: $OUT/ebm_java.csv"
