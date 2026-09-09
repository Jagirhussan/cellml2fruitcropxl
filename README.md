# cellml2fruitcropxl

**CellML-to-Java tooling service for FruitCropXL.** Generates readable, debuggable Java ODE models from CellML 2.0 files, with named fields, by parsing the AST-transformation approach.

## Quick Start

```bash
# Install
pip install -e .

# Generate Java from a CellML model
cellml2fruitcropxl --cellml model.cellml --package org.fruitcropxl.cellml --output-dir gen/

# With package-local service wrapper (adapter surface for FruitCropXL)
cellml2fruitcropxl --cellml model.cellml --package org.fruitcropxl.cellml --output-dir gen/ --with-fruit-service
```

## What It Generates

Given `--cellml jfruit2_oracle.cellml --package org.fruitcropxl.cellml --output-dir gen/`:

```
gen/org/fruitcropxl/cellml/
  AbstractCellmlModel.java     ← Shared abstract base (FirstOrderDifferentialEquations)
  Jfruit2Oracle.java           ← Concrete model (named fields, abstract: user must subclass)
  Jfruit2OracleFruitService.java  ← Optional FruitService wrapper (--with-fruit-service only)
```

### Directory Structure

Files are created under `<output-dir>/<package-path>/`. For `--package org.fruitcropxl.cellml --output-dir gen/`:
```
gen/org/fruitcropxl/cellml/AbstractCellmlModel.java
gen/org/fruitcropxl/cellml/Jfruit2Oracle.java
```

The default package is `org.fruitcropxl.cellml`. FruitCropXL can place the
resulting JAR on its classpath; if it expects its own service interface, use an
explicit adapter in FruitCropXL because Java interface typing is nominal.

## Architecture

### The `applyBoundaryConditions` Pattern

**The tool generates the MATH. The user implements the PHYSICS.**

The generated model class is **abstract** — it does NOT implement `applyBoundaryConditions(double t)`. The user MUST create a subclass:

```java
// Generated (abstract — don't edit):
public abstract class Jfruit2Oracle extends AbstractCellmlModel {
    public double mSuc = 0.05, mSor = 0.02, mFru = 0.01, mGlu = 0.01, mSta = 0.01, mSyn = 0.00;
    public double pasfls = 0.0, bssrat = 0.49, ka0 = 0.05, kb0 = 0.001, ...;
    // ... all model equations as named fields
    // computeRates, computeComputedConstants, loadStates, storeRates — all implemented
    // applyBoundaryConditions — NOT implemented (inherited as abstract)
}

// User writes this:
public class Jfruit2OracleSim extends Jfruit2Oracle {
    @Override
    protected void applyBoundaryConditions(double t) {
        // Set external forcing inputs here — this is YOUR domain logic
        pasfls = interpolatePasfls(t);  // from CSV, interpolation, etc.
    }
}
```

### The `computeDerivatives` Template Method

In `AbstractCellmlModel`:
```java
public void computeDerivatives(double voi, double[] y, double[] yDot) {
    loadStates(y);                    // 1. Copy integrator state → named fields
    applyBoundaryConditions(voi);     // 2. USER sets external inputs (ABSTRACT)
    computeComputedConstants();       // 3. Re-derive constants with user's inputs
    computeRates(voi);                // 4. Compute ODE right-hand side
    storeRates(yDot);                 // 5. Copy named rates → integrator output
}
```

The ordering is critical: `applyBoundaryConditions` is called BEFORE `computeComputedConstants` so that derived constants reflect the updated forcing values.

### Why `applyBoundaryConditions` is Abstract

Forcing the user to implement `applyBoundaryConditions` ensures:
1. The user explicitly handles external inputs (no silent defaults)
2. Different simulations can use different forcing strategies (CSV, climate models, etc.)
3. The generated code has zero model-specific boundary condition logic

## Dependencies

### Without `--with-fruit-service` (default)

The generated model only depends on:
- **Apache Commons Math 3** (for `FirstOrderDifferentialEquations`)

### With `--with-fruit-service`

The tool also generates **package-local** `Model.java` and `FruitServiceAPI.java` — minimal interfaces provided by the package itself, NOT imported from jfruit2. The user doesn't need to know anything about jfruit2.

**Why provide a `Model` interface?** The `Model` interface (5 methods: `init`, `getOLength`, `getOutput`, `compute`, `link`) enables:
1. **Step-driven simulation** — `compute()` advances one step, `getOutput()` reads results
2. **Multi-model coupling** — `link(fms)` exchanges data between models
3. **A small adapter surface** — an explicit adapter in FruitCropXL can delegate to these methods without adding a jfruit2 dependency to generated code

**Two simulation modes** (see `examples/`):

| Mode | Interfaces | Integrator | Example |
|---|---|---|---|
| **Standalone** (default) | `FirstOrderDifferentialEquations` only | User manages (commons-math3) | `StandaloneExample.java` |
| **Package-local service** (`--with-fruit-service`) | `Model` + `FruitServiceAPI` (package-local) | Wrapper owns RK4 | `ServiceExample.java` |

Both modes use the **same model subclass** — the user only writes `applyBoundaryConditions` once.

## Reproducible Apptainer environment

For Linux x86-64 hosts, including newer distributions where the `libcellml 0.7.0`
wheel no longer finds `libxml2.so.2`, build the Ubuntu 24.04 image:

```bash
scripts/apptainer-build.sh
```

The default image is `.apptainer/cellml2fruitcropxl-ubuntu24-py311.sif`. It
contains Python 3.11, `libcellml==0.7.0`, OpenJDK 17, Apache Commons Math 3,
and JupyterLab. The wrappers bind this checkout at
`/workspace/cellml2fruitcropxl` and put its `src/` first on `PYTHONPATH`, so a
host editor changes the code used by the container immediately.

```bash
# Interactive development shell
scripts/apptainer-shell.sh

# Run the live-source CLI
scripts/apptainer-run.sh cellml2fruitcropxl --help

# Generate Java from a tracked model
scripts/apptainer-run.sh \
  cellml2fruitcropxl \
  --cellml cellml/jfruit2_oracle.cellml \
  --package org.fruitcropxl.cellml \
  --output-dir build/generated \
  --force

# Generate, inspect, compile, and numerically smoke-test repository models
scripts/apptainer-test.sh

# Optional localhost JupyterLab interface
scripts/apptainer-jupyter.sh

# Build the generated models as a JAR for FruitCropXL
scripts/apptainer-jar.sh
```

See [apptainer/README.md](apptainer/README.md) for image overrides, fakeroot and
sudo builds, Jupyter settings, remote-host use, metadata inspection, pinned
versions, and the separate external-fixture EBM validation. See
[docs/FRUITCROPXL_JAR.md](docs/FRUITCROPXL_JAR.md) for the complete model-to-JAR
and FruitCropXL classpath workflow.

## Examples

### Example 1: Simple constant forcing (no-op boundary conditions)

```java
public class Jfruit2OracleSim extends Jfruit2Oracle {
    @Override
    protected void applyBoundaryConditions(double t) {
        // No external forcing — use default parameter values from CellML
    }
}

// Usage:
Jfruit2OracleSim model = new Jfruit2OracleSim();
FirstOrderIntegrator integrator = new ClassicalRungeKuttaIntegrator(1.0/24.0); // 1-hour step
double[] y = model.getStates();
double[] yDot = new double[6];
integrator.integrate(model, 0.0, y, 100.0, yDot);
```

### Example 2: Real boundary conditions from CSV (see `examples/Jfruit2OracleRealTest.java`)

```java
public class Jfruit2OracleSim extends Jfruit2Oracle {
    private double[] pasflsTimes, pasflsVals;
    
    public Jfruit2OracleSim(double[] times, double[] pasfls) {
        super();
        this.pasflsTimes = times;
        this.pasflsVals = pasfls;
    }
    
    @Override
    protected void applyBoundaryConditions(double t) {
        // Interpolate pasfls from CSV data
        pasfls = interpLinear(pasflsTimes, pasflsVals, t) * 86400.0;
    }
}
```

### Example 3: Complex model with multiple forcing inputs (Fruit_Sugar_EBM)

```java
public class SugarEbmSupersetSim extends SugarEbmSuperset {
    @Override
    protected void applyBoundaryConditions(double t) {
        // Set all external inputs from climate/CSV data
        u_atm_water = vpdFunc.eval(t);           // VPD from climate CSV
        u_stem_water = psiStemFunc.eval(t);      // stem water potential
        u_sor_base = uSorFunc.eval(t);           // sorbitol unloading rate
        x_phloem_suc_base = xSucFunc.eval(t);    // phloem sucrose concentration
        x_phloem_sor_base = xSorFunc.eval(t);    // phloem sorbitol concentration
        t_rip_base = tRipValue;                 // ripening time
    }
}
```

## CLI Reference

```
cellml2fruitcropxl --cellml <path> [options]

Options:
  --cellml <path>           Path to the CellML (.cellml) file (required)
  --package <pkg>           Java package name (default: org.fruitcropxl.cellml)
  --output-dir <dir>        Output directory root (default: current directory)
  --with-fruit-service      Generate package-local service interfaces and wrapper (no jfruit2 dependency)
  --force                   Overwrite existing files
```

## How the Code Generation Works

1. **libcellml** parses the CellML XML and analyses it (variable classification, topological sort)
2. **libcellml Generator** produces flat Python code with array indices
3. **Python `ast` module** parses the generated Python into an AST
4. **`JavaEmitter`** walks the AST and emits Java with named fields:
   - `states[i]` → `mSuc` (state field name from libcellml metadata)
   - `rates[i]` → `d_mSuc_dt` (derivative field name)
   - `variables[i]` → `k0`, `pasfls`, `flux_k0` (variable field name)
   - `exp(...)` → `Math.exp(...)`
   - `gt_func(a, b)` → `(a > b)` (libcellml piecewise comparison helpers)
   - Python ternary `a if cond else b` → Java `cond ? a : b`
