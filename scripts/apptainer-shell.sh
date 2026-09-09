#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CONTAINER_ROOT="/workspace/cellml2fruitcropxl"
APPTAINER_BIN="${APPTAINER_BIN:-apptainer}"
IMAGE="${CELLML2FRUITCROPXL_IMAGE:-${REPO_ROOT}/.apptainer/cellml2fruitcropxl-ubuntu24-py311.sif}"

if ! command -v "${APPTAINER_BIN}" >/dev/null 2>&1; then
    echo "ERROR: Apptainer is not installed or APPTAINER_BIN is invalid." >&2
    exit 1
fi
if [[ ! -f "${IMAGE}" ]]; then
    echo "ERROR: image not found: ${IMAGE}" >&2
    echo "Build it with scripts/apptainer-build.sh" >&2
    exit 1
fi

exec "${APPTAINER_BIN}" exec \
    --cleanenv \
    --bind "${REPO_ROOT}:${CONTAINER_ROOT}" \
    --pwd "${CONTAINER_ROOT}" \
    --env "PYTHONPATH=${CONTAINER_ROOT}/src" \
    "${IMAGE}" \
    bash "${CONTAINER_ROOT}/apptainer/shell-init.sh"
