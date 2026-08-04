# Reproducible Apptainer environment

This image is an immutable Linux x86-64 execution environment. Development
still happens in the host checkout: every runtime wrapper bind-mounts the
repository at `/workspace/cellml2fruitcropxl` and sets
`PYTHONPATH=/workspace/cellml2fruitcropxl/src`. The installed package snapshot
is available for standalone image use, but the bound host source takes
precedence during the documented workflow.

```text
host checkout                         Apptainer image
cellml2fruitcropxl/  ── bind ──>      /workspace/cellml2fruitcropxl
  src/ (live edits)                    Ubuntu 24.04
                                      Python 3.11 + libcellml 0.7.0
                                      OpenJDK 17 + Commons Math 3
                                      JupyterLab
```

No host Python, Java, Conda, or `libcellml` installation is required. The host
needs Apptainer and must be Linux x86-64.

## Build

From anywhere in the checkout:

```bash
scripts/apptainer-build.sh
```

The script changes to the repository root so the definition's `%files` paths
are deterministic, then runs `apptainer build --fakeroot`. The default output
is:

```text
.apptainer/cellml2fruitcropxl-ubuntu24-py311.sif
```

A valid existing image is reused. Rebuild it explicitly with:

```bash
scripts/apptainer-build.sh --force
```

If this host has no usable fakeroot/subordinate-ID setup, build through the
system installation instead:

```bash
scripts/apptainer-build.sh --sudo
```

The build script prints that sudo alternative when fakeroot fails. To choose a
different image path, either use `--image` while building or set the common
runtime override:

```bash
scripts/apptainer-build.sh --image /data/images/cellml2fruitcropxl.sif
export CELLML2FRUITCROPXL_IMAGE=/data/images/cellml2fruitcropxl.sif
```

`APPTAINER_BIN` may override the Apptainer executable name or path.

## Interactive shell and live host edits

```bash
scripts/apptainer-shell.sh
```

Startup prints the active Python executable, `libcellml` module, and
`cellml2fruitcropxl` module. It also asserts that the package path is exactly
the bind-mounted `src/cellml2fruitcropxl/__init__.py`, rather than the snapshot
inside the image. Keep using VS Code or another host editor; saved changes are
visible immediately in the shell. The `.sif` itself is not modified.

## Generic execution and CLI

The generic wrapper safely forwards each argument:

```bash
scripts/apptainer-run.sh python --version
scripts/apptainer-run.sh python -c "import libcellml"
scripts/apptainer-run.sh cellml2fruitcropxl --help
scripts/apptainer-run.sh python -m cellml2fruitcropxl.cli --help
```

Generate Java from the tracked small model:

```bash
scripts/apptainer-run.sh \
  cellml2fruitcropxl \
  --cellml cellml/jfruit2_oracle.cellml \
  --package org.fruitcropxl.cellml \
  --output-dir build/generated \
  --force
```

Compile it against Ubuntu's packaged Commons Math JAR:

```bash
scripts/apptainer-run.sh \
  javac \
  -cp /usr/share/java/commons-math3.jar \
  build/generated/org/fruitcropxl/cellml/AbstractCellmlModel.java \
  build/generated/org/fruitcropxl/cellml/Jfruit2Oracle.java
```

## Build a JAR for FruitCropXL

Generate both tracked models, compile their repository boundary-condition
subclasses and examples, run the small numerical smoke test, and create a thin
JAR with one command:

```bash
scripts/apptainer-jar.sh
```

The artifact is
`build/fruitcropxl-jar/cellml2fruitcropxl-models.jar`. Rebuild it with
`scripts/apptainer-jar.sh --force`. Apache Commons Math 3 remains an explicit
FruitCropXL runtime dependency rather than being duplicated inside this JAR.

See [the detailed FruitCropXL JAR guide](../docs/FRUITCROPXL_JAR.md) for the
generated class inventory, manual generation and packaging commands, testing
the packaged artifact, Gradle/Maven/direct-classpath examples, EBM data
requirements, and the precise boundary between the package-local service API
and a future FruitCropXL adapter.

## Portable smoke test

```bash
scripts/apptainer-test.sh
```

This checks the native extension with `ldd`, verifies `libcellml==0.7.0`,
generates Java from both models under `cellml/`, checks named-field and abstract
class invariants, compiles the default and package-local FruitService forms
against `/usr/share/java/commons-math3.jar`, and runs a small Java numerical
simulation with NaN/infinity detection. It has no path outside this repository.
Outputs are written under `build/apptainer-smoke/`.

The extended EBM comparison is deliberately separate because its climate,
target, and Python/Radau reference data are not tracked here. It fails preflight
unless all inputs are named explicitly:

```bash
EBM_TARGET_CSV=/data/growth-target.csv \
EBM_CLIMATE_CSV=/data/climate.csv \
EBM_PYTHON_REFERENCE_CSV=/data/ebm-python-radau.csv \
scripts/apptainer-run.sh tests/verify_ebm.sh
```

Optional settings are `EBM_OUTPUT_DIR`, `EBM_ATOL` (default `1e-6`), and
`EBM_RTOL` (default `1e-3`). Missing inputs are an error, not a pass or silent
skip.

## JupyterLab

```bash
scripts/apptainer-jupyter.sh
```

The script generates a random URL-safe authentication token, listens on
`127.0.0.1:8888`, prints the complete local URL, and selects the image's
`Python 3.11 (cellml2fruitcropxl)` kernel. It does not disable authentication.
Override the port or supply a stable token with:

```bash
JUPYTER_PORT=8890 scripts/apptainer-jupyter.sh
JUPYTER_TOKEN=my-url-safe-token scripts/apptainer-jupyter.sh
```

`JUPYTER_BIND_ADDRESS` can override the bind address, but keeping the default
localhost binding and using an SSH tunnel is recommended on remote machines.
Jupyter configuration, data, and runtime state go under the ignored `.jupyter/`
directory. Notebooks and source files are the same bind-mounted files that a
host editor sees; no graphical Linux desktop is installed.

## Pinned architecture and dependencies

- Base: `docker.io/library/ubuntu:24.04`, Linux x86-64.
- Miniconda: `Miniconda3-py311_26.5.3-2-Linux-x86_64.sh`.
- Miniconda SHA-256:
  `cdca3dd8440759bb87c60b227e26946263fe2856b30b2bcfdd964c38254fb8eb`.
- Conda environment prefix: `/opt/conda/envs/cellml2fruitcropxl`.
- Python: `3.11.13`; `libcellml==0.7.0`.
- Java: Ubuntu 24.04 package `openjdk-17-jdk-headless`.
- Commons Math: Ubuntu 24.04 package `libcommons-math3-java`.
- Native XML runtime: Ubuntu 24.04 package `libxml2`, providing the genuine
  `libxml2.so.2` ABI required by the wheel.
- NumPy `2.2.6`, SciPy `1.15.3`, pandas `2.3.0`, matplotlib `3.10.3`,
  JupyterLab `4.4.3`, and ipykernel `6.29.5`.

Python 3.14 is intentionally excluded. The published `libcellml 0.7.0` artifact
used by this project is a CPython 3.11 Linux x86-64 binary wheel, so permitting
newer unsupported interpreters in package metadata would make installation fail
or misrepresent support. Ubuntu 24.04 supplies `libxml2.so.2` directly; the
image does not create an incompatible SONAME symlink and does not modify the
newer host OS.

Miniconda's defaults channels are used and their terms are accepted during the
non-interactive image build. Review Anaconda's current terms for your intended
use before distributing the resulting image.

## Metadata, generated files, and remote hosts

The build records the resolved OS, Python packages, Java version, and relevant
Ubuntu package versions in `/opt/cellml2fruitcropxl-build-info.txt`. Inspect it
and the embedded definition/labels with:

```bash
scripts/apptainer-run.sh cat /opt/cellml2fruitcropxl-build-info.txt
apptainer inspect --all .apptainer/cellml2fruitcropxl-ubuntu24-py311.sif
apptainer inspect --deffile .apptainer/cellml2fruitcropxl-ubuntu24-py311.sif
```

The `.gitignore` excludes `.apptainer/`, all `*.sif` images, `build/`,
`.jupyter/`, and notebook checkpoint directories. The generated image is never
part of the Git checkout.

For a remote Linux x86-64 host, copy both the checkout and the `.sif` (or build
the image there), set `CELLML2FRUITCROPXL_IMAGE` if it is outside the default
location, and run the same wrappers. The wrappers calculate the remote checkout
path dynamically and bind it to the stable container path. For remote
JupyterLab, keep it on `127.0.0.1` and tunnel the chosen port, for example
`ssh -L 8888:127.0.0.1:8888 remote-host`.
