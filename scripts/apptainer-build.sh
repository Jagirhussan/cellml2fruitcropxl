#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DEF_FILE="${REPO_ROOT}/apptainer/cellml2fruitcropxl.def"
APPTAINER_BIN="${APPTAINER_BIN:-apptainer}"
IMAGE="${CELLML2FRUITCROPXL_IMAGE:-${REPO_ROOT}/.apptainer/cellml2fruitcropxl-ubuntu24-py311.sif}"
FORCE=0
USE_SUDO=0

usage() {
    cat <<'USAGE'
Usage: scripts/apptainer-build.sh [--force] [--sudo] [--image PATH]

Build the Ubuntu 24.04 / Python 3.11 Apptainer image with fakeroot by default.

Options:
  --force       Rebuild and overwrite an existing image.
  --sudo        Use "sudo apptainer build" instead of fakeroot.
  --image PATH  Override the image path for this build.
  -h, --help    Show this help.

The CELLML2FRUITCROPXL_IMAGE environment variable also overrides the image path.
USAGE
}

while (($#)); do
    case "$1" in
        --force)
            FORCE=1
            shift
            ;;
        --sudo)
            USE_SUDO=1
            shift
            ;;
        --image)
            if (($# < 2)); then
                echo "ERROR: --image requires a path" >&2
                exit 2
            fi
            IMAGE="$2"
            shift 2
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

case "${IMAGE}" in
    /*) ;;
    *) IMAGE="${REPO_ROOT}/${IMAGE}" ;;
esac

if ! command -v "${APPTAINER_BIN}" >/dev/null 2>&1; then
    echo "ERROR: Apptainer is not installed or APPTAINER_BIN is invalid." >&2
    exit 1
fi

case "$(uname -m)" in
    x86_64|amd64) ;;
    *)
        echo "ERROR: this image targets Linux x86-64; host architecture is $(uname -m)." >&2
        exit 1
        ;;
esac

if [[ -e "${IMAGE}" && ${FORCE} -eq 0 ]]; then
    if "${APPTAINER_BIN}" inspect "${IMAGE}" >/dev/null 2>&1; then
        echo "Using existing valid image: ${IMAGE}"
        echo "Use --force to rebuild it."
        exit 0
    fi
    echo "ERROR: ${IMAGE} exists but is not a valid Apptainer image." >&2
    echo "Re-run with --force to replace it." >&2
    exit 1
fi

mkdir -p "$(dirname -- "${IMAGE}")"
REVISION="$(git -C "${REPO_ROOT}" rev-parse HEAD 2>/dev/null || printf 'unknown')"

BUILD_ARGS=(build)
if [[ ${USE_SUDO} -eq 1 ]]; then
    BUILD_CMD=(sudo "${APPTAINER_BIN}")
else
    BUILD_CMD=("${APPTAINER_BIN}")
    BUILD_ARGS+=(--fakeroot)
fi
if [[ ${FORCE} -eq 1 ]]; then
    BUILD_ARGS+=(--force)
fi
BUILD_ARGS+=(--build-arg "REPOSITORY_REVISION=${REVISION}" "${IMAGE}" "${DEF_FILE}")

echo "Building ${IMAGE}"
echo "Build context: ${REPO_ROOT}"
cd "${REPO_ROOT}"

if ! "${BUILD_CMD[@]}" "${BUILD_ARGS[@]}"; then
    if [[ ${USE_SUDO} -eq 0 ]]; then
        printf '\nBuild failed; review the error above. If it reports that fakeroot is unavailable, use:\n  '
        printf '%q ' "${0}" --sudo
        if [[ ${FORCE} -eq 1 ]]; then
            printf '%q ' --force
        fi
        printf '%q %q\n' --image "${IMAGE}"
    fi
    exit 1
fi

echo "Built image: ${IMAGE}"
