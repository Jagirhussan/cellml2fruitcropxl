#!/usr/bin/env bash
# Generate, compile, smoke-test, and package the tracked CellML models as a thin JAR.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
RUNNER="${SCRIPT_DIR}/apptainer-run.sh"
OUTPUT_ROOT="${REPO_ROOT}/build/fruitcropxl-jar"
OUTPUT_REL="build/fruitcropxl-jar"
GENERATED_REL="${OUTPUT_REL}/generated"
CLASSES_REL="${OUTPUT_REL}/classes"
JAR_REL="${OUTPUT_REL}/cellml2fruitcropxl-models.jar"
JAR_PATH="${REPO_ROOT}/${JAR_REL}"
COMMONS_MATH_JAR="/usr/share/java/commons-math3.jar"
PACKAGE="org.fruitcropxl.cellml"
PACKAGE_PATH="org/fruitcropxl/cellml"
FORCE=0

usage() {
    cat <<'USAGE'
Usage: scripts/apptainer-jar.sh [--force]

Use the Apptainer image to generate both tracked CellML models, compile the
generated Java and repository examples, run the small numerical smoke test,
and create:

  build/fruitcropxl-jar/cellml2fruitcropxl-models.jar

The result is a thin JAR. FruitCropXL must also provide Apache Commons Math 3
at runtime. Use --force to replace an existing output directory.
USAGE
}

while (($#)); do
    case "$1" in
        --force)
            FORCE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [[ ! -x "${RUNNER}" ]]; then
    echo "ERROR: runtime wrapper is unavailable: ${RUNNER}" >&2
    exit 1
fi

if [[ -e "${OUTPUT_ROOT}" ]]; then
    if [[ ${FORCE} -ne 1 ]]; then
        echo "ERROR: output already exists: ${OUTPUT_ROOT}" >&2
        echo "Re-run with --force to regenerate it." >&2
        exit 1
    fi
    case "${OUTPUT_ROOT}" in
        "${REPO_ROOT}/build/fruitcropxl-jar")
            rm -rf -- "${OUTPUT_ROOT}"
            ;;
        *)
            echo "ERROR: refusing to remove unexpected output path: ${OUTPUT_ROOT}" >&2
            exit 1
            ;;
    esac
fi

mkdir -p "${OUTPUT_ROOT}/generated" "${OUTPUT_ROOT}/classes"

echo "== Generate Jfruit2Oracle with package-local service wrapper =="
"${RUNNER}" cellml2fruitcropxl \
    --cellml cellml/jfruit2_oracle.cellml \
    --package "${PACKAGE}" \
    --output-dir "${GENERATED_REL}" \
    --with-fruit-service \
    --force

echo "== Generate SugarEbmSuperset =="
"${RUNNER}" cellml2fruitcropxl \
    --cellml cellml/Fruit_Sugar_EBM.cellml \
    --package "${PACKAGE}" \
    --output-dir "${GENERATED_REL}" \
    --force

echo "== Compile generated models, boundary-condition subclasses, and examples =="
"${RUNNER}" javac \
    -d "${CLASSES_REL}" \
    -cp "${COMMONS_MATH_JAR}" \
    "${GENERATED_REL}/${PACKAGE_PATH}/AbstractCellmlModel.java" \
    "${GENERATED_REL}/${PACKAGE_PATH}/Jfruit2Oracle.java" \
    "${GENERATED_REL}/${PACKAGE_PATH}/Jfruit2OracleFruitService.java" \
    "${GENERATED_REL}/${PACKAGE_PATH}/Model.java" \
    "${GENERATED_REL}/${PACKAGE_PATH}/FruitServiceAPI.java" \
    "${GENERATED_REL}/${PACKAGE_PATH}/SugarEbmSuperset.java" \
    examples/Jfruit2OracleSim.java \
    examples/SugarEbmSupersetSim.java \
    examples/StandaloneExample.java \
    examples/ServiceExample.java \
    examples/EBMExample.java

echo "== Package compiled classes and original CellML resources =="
"${RUNNER}" jar --create \
    --file "${JAR_REL}" \
    -C "${CLASSES_REL}" . \
    -C . cellml/jfruit2_oracle.cellml \
    -C . cellml/Fruit_Sugar_EBM.cellml
chmod 0644 "${JAR_PATH}"

"${RUNNER}" jar --list --file "${JAR_REL}" > "${OUTPUT_ROOT}/jar-contents.txt"

required_entries=(
    "org/fruitcropxl/cellml/Jfruit2Oracle.class"
    "org/fruitcropxl/cellml/Jfruit2OracleSim.class"
    "org/fruitcropxl/cellml/Jfruit2OracleFruitService.class"
    "org/fruitcropxl/cellml/SugarEbmSuperset.class"
    "org/fruitcropxl/cellml/SugarEbmSupersetSim.class"
    "cellml/jfruit2_oracle.cellml"
    "cellml/Fruit_Sugar_EBM.cellml"
)
for entry in "${required_entries[@]}"; do
    if ! grep -Fxq "${entry}" "${OUTPUT_ROOT}/jar-contents.txt"; then
        echo "ERROR: expected JAR entry is missing: ${entry}" >&2
        exit 1
    fi
done

echo "== Run standalone and service examples from the packaged JAR =="
"${RUNNER}" java \
    -cp "${JAR_REL}:${COMMONS_MATH_JAR}" \
    org.fruitcropxl.cellml.StandaloneExample \
    > "${OUTPUT_ROOT}/standalone-from-jar.csv"
"${RUNNER}" java \
    -cp "${JAR_REL}:${COMMONS_MATH_JAR}" \
    org.fruitcropxl.cellml.ServiceExample \
    > "${OUTPUT_ROOT}/service-from-jar.csv"

for output in \
    "${OUTPUT_ROOT}/standalone-from-jar.csv" \
    "${OUTPUT_ROOT}/service-from-jar.csv"; do
    if [[ "$(wc -l < "${output}")" -lt 2 ]]; then
        echo "ERROR: packaged-JAR smoke test produced no data rows: ${output}" >&2
        exit 1
    fi
    if grep -Eiq '(^|,)(nan|[-+]?infinity)(,|$)' "${output}"; then
        echo "ERROR: packaged-JAR smoke test produced NaN or infinity: ${output}" >&2
        exit 1
    fi
done

"${RUNNER}" sha256sum "${JAR_REL}" > "${OUTPUT_ROOT}/cellml2fruitcropxl-models.jar.sha256"

echo
echo "JAR created: ${JAR_PATH}"
echo "JAR contents: ${OUTPUT_ROOT}/jar-contents.txt"
echo "Generated Java: ${OUTPUT_ROOT}/generated"
echo "Smoke outputs: ${OUTPUT_ROOT}/*-from-jar.csv"
echo "Checksum: ${OUTPUT_ROOT}/cellml2fruitcropxl-models.jar.sha256"
echo
echo "Runtime dependency: Apache Commons Math 3"
echo "Container path: ${COMMONS_MATH_JAR}"
