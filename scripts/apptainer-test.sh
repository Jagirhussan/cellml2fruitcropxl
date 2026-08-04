#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

exec "${SCRIPT_DIR}/apptainer-run.sh" bash -c '
set -euo pipefail

python --version
python -c "from importlib.metadata import version; assert version(\"libcellml\") == \"0.7.0\""

extension="$(python -c "import libcellml, pathlib; print(next(pathlib.Path(libcellml.__file__).parent.glob(\"_analyser.so\")))")"
echo "Native extension: ${extension}"
linkage="$(ldd "${extension}")"
echo "${linkage}"
if grep -q "not found" <<<"${linkage}"; then
    echo "ERROR: unresolved libcellml native dependency" >&2
    exit 1
fi

test -r /usr/share/java/commons-math3.jar
PYTHON=python COMMONS_MATH_JAR=/usr/share/java/commons-math3.jar tests/verify.sh
'
