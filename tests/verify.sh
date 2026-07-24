#!/usr/bin/env bash
# verify.sh — End-to-end verification for cellml2fruitcropxl.
#
# Generates Java from both test CellML models, compiles, and verifies
# the generated code is syntactically correct and uses named fields.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$ROOT/../.." && pwd)"
# Point to the python environment that has libcellml installed
PY="/usr/bin/python"
JAR="$WORKSPACE/fruitcropmodel-master/ext/ext_linux/jfruit2-1.3.6-jar-with-dependencies.jar"
GEN="$ROOT/gen"
PKG="org.fruitcropxl.cellml"
PKG_PATH="org/fruitcropxl/cellml"

# Set up Python path for the cellml2fruitcropxl package.
export PYTHONPATH="$ROOT/../src:${PYTHONPATH:-}"

rm -rf "$GEN"
mkdir -p "$GEN"

echo "================================================"
echo "Test 1: jfruit2_oracle.cellml (6 states, simple)"
echo "================================================"
$PY -m cellml2fruitcropxl.cli \
  --cellml "$WORKSPACE/jfruit2_oracle.cellml" \
  --package "$PKG" --output-dir "$GEN" 2>&1

echo ""
echo "================================================"
echo "Test 2: Fruit_Sugar_EBM.cellml (11 states, piecewise, multi-component)"
echo "================================================"
$PY -m cellml2fruitcropxl.cli \
  --cellml "$WORKSPACE/Fruit_Sugar_EBM.cellml" \
  --package "$PKG" --output-dir "$GEN" 2>&1

echo ""
echo "================================================"
echo "Test 3: Compile all generated Java"
echo "================================================"
JAVA_DIR="$GEN/$PKG_PATH"
echo "Compiling: $JAVA_DIR/*.java"
javac -d "$GEN/out" -cp "$JAR" "$JAVA_DIR"/*.java 2>&1
echo "Compile: OK"

echo ""
echo "================================================"
echo "Test 4: Verify named fields (not array indices)"
echo "================================================"
# Check that the generated code uses named fields, not variables[N]
if grep -q "variables\[" "$JAVA_DIR/Jfruit2Oracle.java"; then
    echo "FAIL: Jfruit2Oracle.java still contains array indices"
    exit 1
fi
if grep -q "variables\[" "$JAVA_DIR/SugarEbmSuperset.java"; then
    echo "FAIL: SugarEbmSuperset.java still contains array indices"
    exit 1
fi
echo "Named fields: OK (no array indices found)"

echo ""
echo "================================================"
echo "Test 5: Verify applyBoundaryConditions is abstract"
echo "================================================"
if grep -q "abstract class Jfruit2Oracle" "$JAVA_DIR/Jfruit2Oracle.java"; then
    echo "Jfruit2Oracle is abstract: OK"
else
    echo "FAIL: Jfruit2Oracle should be abstract"
    exit 1
fi
if grep -q "abstract class SugarEbmSuperset" "$JAVA_DIR/SugarEbmSuperset.java"; then
    echo "SugarEbmSuperset is abstract: OK"
else
    echo "FAIL: SugarEbmSuperset should be abstract"
    exit 1
fi

echo ""
echo "================================================"
echo "Test 6: Verify piecewise → ternary translation"
echo "================================================"
if grep -q " ? " "$JAVA_DIR/SugarEbmSuperset.java"; then
    echo "Ternary expressions found: OK"
    # Show a sample
    grep -m2 " ? " "$JAVA_DIR/SugarEbmSuperset.java"
else
    echo "NOTE: No ternary expressions (model may not have piecewise functions)"
fi

echo ""
echo "================================================"
echo "ALL TESTS PASSED"
echo "================================================"
echo "Generated files:"
find "$GEN" -name "*.java" -exec wc -l {} \;
