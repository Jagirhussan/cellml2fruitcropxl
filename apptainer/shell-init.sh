#!/usr/bin/env bash
set -euo pipefail

python - <<'PYTHON'
from pathlib import Path
import sys

import cellml2fruitcropxl
import libcellml

expected = Path("/workspace/cellml2fruitcropxl/src/cellml2fruitcropxl/__init__.py").resolve()
package_path = Path(cellml2fruitcropxl.__file__).resolve()

print(f"Python:               {sys.executable} ({sys.version.split()[0]})")
print(f"libcellml:            {Path(libcellml.__file__).resolve()}")
print(f"cellml2fruitcropxl:   {package_path}")
print(f"Expected live source: {expected}")

if package_path != expected:
    raise SystemExit("ERROR: the bind-mounted src/ package is not taking precedence")

print("Live-source precedence: OK")
PYTHON

printf '\nThe host repository is writable at /workspace/cellml2fruitcropxl.\n'
printf 'Host-editor changes are visible immediately in this shell.\n\n'
exec bash --noprofile --norc -i
