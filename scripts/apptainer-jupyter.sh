#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CONTAINER_ROOT="/workspace/cellml2fruitcropxl"
APPTAINER_BIN="${APPTAINER_BIN:-apptainer}"
IMAGE="${CELLML2FRUITCROPXL_IMAGE:-${REPO_ROOT}/.apptainer/cellml2fruitcropxl-ubuntu24-py311.sif}"
PORT="${JUPYTER_PORT:-8888}"
BIND_ADDRESS="${JUPYTER_BIND_ADDRESS:-127.0.0.1}"
TOKEN="${JUPYTER_TOKEN:-}"

if ! command -v "${APPTAINER_BIN}" >/dev/null 2>&1; then
    echo "ERROR: Apptainer is not installed or APPTAINER_BIN is invalid." >&2
    exit 1
fi
if [[ ! -f "${IMAGE}" ]]; then
    echo "ERROR: image not found: ${IMAGE}" >&2
    echo "Build it with scripts/apptainer-build.sh" >&2
    exit 1
fi
if [[ ! "${PORT}" =~ ^[0-9]+$ ]] || ((PORT < 1 || PORT > 65535)); then
    echo "ERROR: JUPYTER_PORT must be an integer from 1 to 65535." >&2
    exit 2
fi
if [[ -z "${TOKEN}" ]]; then
    TOKEN="$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')"
fi
if [[ "${TOKEN}" == *[^A-Za-z0-9._~-]* ]]; then
    echo "ERROR: JUPYTER_TOKEN must contain only URL-safe characters." >&2
    exit 2
fi

mkdir -p "${REPO_ROOT}/.jupyter/data" "${REPO_ROOT}/.jupyter/runtime"

echo "Starting JupyterLab with the container's Python 3.11 kernel."
echo "Repository: ${REPO_ROOT} -> ${CONTAINER_ROOT}"
echo "Open: http://${BIND_ADDRESS}:${PORT}/lab?token=${TOKEN}"
echo "The same files may be edited concurrently with VS Code or another host editor."

exec "${APPTAINER_BIN}" exec \
    --cleanenv \
    --bind "${REPO_ROOT}:${CONTAINER_ROOT}" \
    --pwd "${CONTAINER_ROOT}" \
    --env "PYTHONPATH=${CONTAINER_ROOT}/src" \
    --env "JUPYTER_CONFIG_DIR=${CONTAINER_ROOT}/.jupyter" \
    --env "JUPYTER_DATA_DIR=${CONTAINER_ROOT}/.jupyter/data" \
    --env "JUPYTER_RUNTIME_DIR=${CONTAINER_ROOT}/.jupyter/runtime" \
    "${IMAGE}" \
    jupyter lab \
        --ServerApp.ip="${BIND_ADDRESS}" \
        --ServerApp.port="${PORT}" \
        --ServerApp.port_retries=0 \
        --ServerApp.open_browser=False \
        --ServerApp.root_dir="${CONTAINER_ROOT}" \
        --IdentityProvider.token="${TOKEN}" \
        --MultiKernelManager.default_kernel_name=cellml2fruitcropxl
