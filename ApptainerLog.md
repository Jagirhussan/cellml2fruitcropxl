• Implemented and validated the complete Apptainer workflow on the Ubuntu 26 host.

  1. Files added and modified

  Added:

  - cellml2fruitcropxl/apptainer/README.md
  - cellml2fruitcropxl/apptainer/environment.yml
  - cellml2fruitcropxl/scripts/apptainer-run.sh
  - cellml2fruitcropxl/.gitignore

  Modified:

  - cellml2fruitcropxl/pyproject.toml
  - cellml2fruitcropxl/README.md
  - cellml2fruitcropxl/tests/verify.sh
  - cellml2fruitcropxl/tests/verify_ebm.sh
  - Generator, emitter, and metadata handling for the actual libcellml 0.7 API.

  The pre-existing untracked .python-version was left untouched.

  2. Final architecture

  The image contains Ubuntu 24.04, Miniconda, Python, libcellml, OpenJDK, Commons Math, and a package snapshot. Runtime
  wrappers bind the host repository at /workspace/cellml2fruitcropxl and prepend its src/ directory to PYTHONPATH, so host
  edits take precedence without rebuilding.

  3. Versions

  - Ubuntu: 24.04 base, resolved as Ubuntu 24.04.4 LTS
  - Miniconda: Miniconda3-py311_26.5.3-2-Linux-x86_64.sh
  - Miniconda SHA-256: cdca3dd8440759bb87c60b227e26946263fe2856b30b2bcfdd964c38254fb8eb
  - Python: 3.11.13
  - libcellml: 0.7.0
  - OpenJDK: 17.0.19
  - Commons Math: Ubuntu package 3.6.1-3
  - libxml2: Ubuntu package 2.9.14+dfsg-1.3ubuntu3.8
  - JupyterLab: 4.4.3

  Resolved packages and system information are recorded inside /opt/cellml2fruitcropxl-build-info.txt.

  4. Packaging corrections

  - Corrected backend to setuptools.build_meta.
  - Restricted Python to >=3.10,<3.12.
  - Pinned libcellml==0.7.0.
  - Preserved the package name, GPL declaration, CLI entry point, and source layout.

  5. Test assumptions removed

  The required smoke test no longer uses /usr/bin/python, outside workspaces, neighbouring repositories, or the external
  jfruit2 fat JAR. It uses repository CellML models, an ignored build/ directory, and /usr/share/java/commons-math3.jar.

  6. Validation executed

  Executed the build, Python/import checks, both CLI forms, repository smoke test, generated-Java compilation, interactive
  shell, live-source precedence check, Jupyter launch, git diff --check, and Bash syntax validation. ShellCheck was unavailable
  locally.

  7. Image build result

  Successful:

  .apptainer/cellml2fruitcropxl-ubuntu24-py311.sif
  880,287,744 bytes

  The image’s %test section passed. A repeated build without --force correctly reused the valid image.

  8. libcellml result

  libcellml 0.7.0
  /opt/conda/envs/cellml2fruitcropxl/lib/python3.11/site-packages/libcellml/__init__.py

  ldd found no unresolved libraries. libxml2.so.2 resolves to Ubuntu 24.04’s real library; no SONAME symlink workaround is
  used.

  9. Java result

  Both bundled CellML models generated successfully. Generated sources, package-local interfaces, wrappers, and examples
  compiled against /usr/share/java/commons-math3.jar. The numerical smoke execution completed 2,400 steps without NaN or
  infinity.

  10. JupyterLab result

  JupyterLab reached the running state at a token-authenticated http://127.0.0.1:8888/lab URL, served the bind-mounted
  repository, and used the container Python kernel. It was then shut down cleanly.

  11. External EBM inputs

  Extended EBM comparison still requires:

  - EBM_TARGET_CSV
  - EBM_CLIMATE_CSV
  - EBM_PYTHON_REFERENCE_CSV

  Missing inputs now produce a detailed preflight error and exit status 2; they are never reported as a passed or skipped
  numerical validation.

  12. Remaining considerations

  The image targets Linux x86-64. Rebuilds resolve Ubuntu and transitive Python packages from their repositories, while the
  exact resolved state is recorded in the image manifest rather than being guaranteed bit-for-bit forever. Miniconda/default-
  channel terms should be reviewed by downstream users. No third-party EBM data was added; the pre-existing CellML models do
  not appear to contain separate per-file licensing notices.
