# Build and use the FruitCropXL model JAR with Apptainer

This guide starts from a clean `cellml2fruitcropxl` checkout and produces a
Java library that can be added to a FruitCropXL build. The host needs Linux
x86-64 and Apptainer; Python, Conda, `libcellml`, Java, and Commons Math are
provided by the image.

The documented workflow uses the live host checkout. The immutable SIF contains
the toolchain and an installed package snapshot, while the scripts bind the
checkout at `/workspace/cellml2fruitcropxl`. Consequently, the tracked CellML
models, Java examples, and current Python source are visible inside the
container, and host-side edits are used immediately.

## 1. Build or select the image

From the repository root:

```bash
scripts/apptainer-build.sh
```

This creates:

```text
.apptainer/cellml2fruitcropxl-ubuntu24-py311.sif
```

The existing image is reused. Use `scripts/apptainer-build.sh --force` after a
definition or packaged-source change. If fakeroot is unavailable, use
`scripts/apptainer-build.sh --sudo`. For an image stored elsewhere:

```bash
export CELLML2FRUITCROPXL_IMAGE=/data/images/cellml2fruitcropxl.sif
```

Verify the active toolchain:

```bash
scripts/apptainer-run.sh python --version
scripts/apptainer-run.sh python -c \
  "import libcellml; from importlib.metadata import version; print(version('libcellml'), libcellml.__file__)"
scripts/apptainer-run.sh java -version
scripts/apptainer-run.sh javac -version
scripts/apptainer-run.sh test -r /usr/share/java/commons-math3.jar
```

## 2. Understand the two tracked models

The repository currently contains:

| CellML source | Generated abstract class | Concrete repository subclass | Inputs |
|---|---|---|---|
| `cellml/jfruit2_oracle.cellml` | `Jfruit2Oracle` | `Jfruit2OracleSim` | Constant or supplied `pasfls` |
| `cellml/Fruit_Sugar_EBM.cellml` | `SugarEbmSuperset` | `SugarEbmSupersetSim` | Climate and target CSV series |

Generated model classes are deliberately abstract. They contain the CellML
equations but require a subclass that implements
`applyBoundaryConditions(double t)`. The repository subclasses demonstrate the
required boundary conditions:

- `examples/Jfruit2OracleSim.java` is self-contained and uses a configurable
  constant `pasfls` value.
- `examples/SugarEbmSupersetSim.java` loads climate and target CSV inputs. It
  compiles into the JAR, but numerical EBM execution still requires the external
  CSV files documented in `tests/verify_ebm.sh`.

Edit or replace these subclasses before packaging if FruitCropXL supplies
forcing data through a different API. Do not edit generated classes, because a
later generation overwrites them.

## 3. Produce the JAR in one command

Run:

```bash
scripts/apptainer-jar.sh
```

If an earlier result exists:

```bash
scripts/apptainer-jar.sh --force
```

The script performs these operations inside the image:

1. Generates `Jfruit2Oracle`, the package-local service interfaces, and
   `Jfruit2OracleFruitService`.
2. Generates `SugarEbmSuperset`.
3. Compiles both generated models, both boundary-condition subclasses, and the
   repository examples with OpenJDK 17.
4. Packages the compiled classes and original CellML files.
5. Verifies the expected classes and model resources in the finished JAR.
6. Runs both `StandaloneExample` and `ServiceExample` from the packaged JAR and
   rejects missing output, NaN, or infinity.
7. Writes a SHA-256 checksum for artifact handoff.

Only `Jfruit2Oracle` receives the generated service wrapper. The current generic
wrapper maps `fromArray(..., values)` to one `pasfls` value. The EBM model has six
domain-specific forcing inputs, so generating an EBM wrapper would compile but
would not provide correct input semantics. `SugarEbmSuperset` and its concrete
CSV-driven subclass are still included in the JAR; a FruitCropXL EBM adapter
must map all six inputs explicitly.

Outputs are:

```text
build/fruitcropxl-jar/
├── cellml2fruitcropxl-models.jar   # binary library for FruitCropXL
├── generated/                      # generated Java source for inspection
├── classes/                        # compiled class tree
├── jar-contents.txt                # reproducible JAR inventory
├── cellml2fruitcropxl-models.jar.sha256
├── standalone-from-jar.csv         # standalone packaged-JAR smoke output
└── service-from-jar.csv            # service packaged-JAR smoke output
```

All of `build/` is ignored by Git.

The result is intentionally a **thin JAR**: it does not copy Apache Commons Math
classes into the artifact. FruitCropXL must provide Commons Math 3 on its build
and runtime classpath. This avoids duplicate library classes when FruitCropXL
already depends on Commons Math.

## 4. Reproduce the generation manually

The one-command builder is recommended, but the equivalent commands make each
stage explicit.

Generate the small model and its package-local service wrapper:

```bash
scripts/apptainer-run.sh \
  cellml2fruitcropxl \
  --cellml cellml/jfruit2_oracle.cellml \
  --package org.fruitcropxl.cellml \
  --output-dir build/manual-jar/generated \
  --with-fruit-service \
  --force
```

Generate the EBM model:

```bash
scripts/apptainer-run.sh \
  cellml2fruitcropxl \
  --cellml cellml/Fruit_Sugar_EBM.cellml \
  --package org.fruitcropxl.cellml \
  --output-dir build/manual-jar/generated \
  --force
```

The relevant generated files appear under:

```text
build/manual-jar/generated/org/fruitcropxl/cellml/
├── AbstractCellmlModel.java
├── Jfruit2Oracle.java
├── Jfruit2OracleFruitService.java
├── Model.java
├── FruitServiceAPI.java
└── SugarEbmSuperset.java
```

Create a classes directory and compile:

```bash
mkdir -p build/manual-jar/classes

scripts/apptainer-run.sh javac \
  -d build/manual-jar/classes \
  -cp /usr/share/java/commons-math3.jar \
  build/manual-jar/generated/org/fruitcropxl/cellml/AbstractCellmlModel.java \
  build/manual-jar/generated/org/fruitcropxl/cellml/Jfruit2Oracle.java \
  build/manual-jar/generated/org/fruitcropxl/cellml/Jfruit2OracleFruitService.java \
  build/manual-jar/generated/org/fruitcropxl/cellml/Model.java \
  build/manual-jar/generated/org/fruitcropxl/cellml/FruitServiceAPI.java \
  build/manual-jar/generated/org/fruitcropxl/cellml/SugarEbmSuperset.java \
  examples/Jfruit2OracleSim.java \
  examples/SugarEbmSupersetSim.java
```

Package the classes and original CellML resources:

```bash
scripts/apptainer-run.sh jar --create \
  --file build/manual-jar/cellml2fruitcropxl-models.jar \
  -C build/manual-jar/classes . \
  -C . cellml/jfruit2_oracle.cellml \
  -C . cellml/Fruit_Sugar_EBM.cellml
```

Inspect the result:

```bash
scripts/apptainer-run.sh jar --list \
  --file build/manual-jar/cellml2fruitcropxl-models.jar
```

## 5. Test the packaged JAR itself

The examples have `main` methods and are included by the automated builder.
Run the standalone and service forms from the packaged artifact:

```bash
scripts/apptainer-run.sh java \
  -cp build/fruitcropxl-jar/cellml2fruitcropxl-models.jar:/usr/share/java/commons-math3.jar \
  org.fruitcropxl.cellml.StandaloneExample \
  > build/fruitcropxl-jar/standalone-from-jar.csv

scripts/apptainer-run.sh java \
  -cp build/fruitcropxl-jar/cellml2fruitcropxl-models.jar:/usr/share/java/commons-math3.jar \
  org.fruitcropxl.cellml.ServiceExample \
  > build/fruitcropxl-jar/service-from-jar.csv
```

The builder already checks that neither output contains `NaN` or `Infinity`.
The commands are shown here so consumers can repeat the checks independently.

The EBM example additionally needs the external target and climate CSV files.
Use the validated extended test rather than invoking it without data:

```bash
EBM_TARGET_CSV=/data/growth-target.csv \
EBM_CLIMATE_CSV=/data/climate.csv \
EBM_PYTHON_REFERENCE_CSV=/data/ebm-python-radau.csv \
scripts/apptainer-run.sh tests/verify_ebm.sh
```

## 6. Add the JAR to FruitCropXL

Copy or reference:

```text
build/fruitcropxl-jar/cellml2fruitcropxl-models.jar
```

FruitCropXL also needs Apache Commons Math 3. For a direct `javac` build:

```bash
javac \
  -cp /path/to/cellml2fruitcropxl-models.jar:/path/to/commons-math3.jar \
  -d build/classes \
  path/to/YourFruitCropXLIntegration.java
```

At runtime, use the same two JARs:

```bash
java \
  -cp build/classes:/path/to/cellml2fruitcropxl-models.jar:/path/to/commons-math3.jar \
  your.fruitcropxl.Main
```

For Gradle, a local-file dependency can be declared as:

```groovy
dependencies {
    implementation files('libs/cellml2fruitcropxl-models.jar')
    implementation 'org.apache.commons:commons-math3:3.6.1'
}
```

For Maven, install the local artifact and then declare it normally:

```bash
mvn install:install-file \
  -Dfile=cellml2fruitcropxl-models.jar \
  -DgroupId=org.fruitcropxl \
  -DartifactId=cellml-models \
  -Dversion=0.1.0 \
  -Dpackaging=jar
```

Application code can directly use the concrete repository model:

```java
import org.fruitcropxl.cellml.Jfruit2OracleSim;
import org.fruitcropxl.cellml.Jfruit2OracleFruitService;

Jfruit2OracleSim model = new Jfruit2OracleSim(0.01);
Jfruit2OracleFruitService service =
    new Jfruit2OracleFruitService(model, 60); // 60-minute step
service.init();
service.fromArray(60, new double[] {0.02}); // age in minutes, current pasfls
service.step();
double[] state = service.getRawValues();
```

For `Jfruit2OracleSim`, `fromArray` can replace `pasfls` at each step. Its
`applyBoundaryConditions` implementation deliberately leaves that field intact.
The generated wrapper currently defines only this one-element forcing mapping;
additional FruitCropXL inputs require an explicit adapter or a specialized
wrapper.

## 7. FruitCropXL adapter boundary

`Jfruit2OracleFruitService`, `Model`, and `FruitServiceAPI` are generated in
`org.fruitcropxl.cellml`. They have no compile-time jfruit2 dependency. They can
be called directly as shown above.

They are **not automatically instances of an interface declared in another
FruitCropXL or jfruit2 package**. Java interface compatibility is nominal, not
structural: identical method signatures alone are insufficient. If FruitCropXL
expects, for example, its own `FruitService` or `Model` type, its integration
module must provide an adapter that implements that exact interface and
delegates to `Jfruit2OracleFruitService`.

That graph/organ service adapter is intentionally outside this repository task.
Before writing it, confirm the exact FruitCropXL interface, package name,
constructor lifecycle, units, time-step convention, forcing-vector ordering,
and output-name contract. Do not rename or relocate the generated package merely
to imitate an external interface; add an explicit adapter in the consuming
FruitCropXL project.

## 8. Updating a model and rebuilding

After changing a `.cellml` file, converter source, or boundary-condition
subclass:

```bash
scripts/apptainer-test.sh
scripts/apptainer-jar.sh --force
```

You normally do not rebuild the SIF for host-side source or model changes,
because the checkout is bind-mounted. Rebuild the SIF only when the definition,
Conda environment, or desired immutable package snapshot changes.

Before handing the JAR to FruitCropXL, retain `jar-contents.txt`, record the Git
revision, and archive the exact CellML inputs alongside the artifact. The JAR
already embeds the two tracked CellML sources under `cellml/` for traceability.
