# AGENTS.md — Guide for AI Agents Using cellml2fruitcropxl

## What This Tool Does

`cellml2fruitcropxl` generates readable Java ODE model classes from CellML 2.0 files. The generated classes have **named fields** (not opaque array indices) and implement `FirstOrderDifferentialEquations` (Apache Commons Math). The generated model is **abstract** — the user must create a subclass and implement `applyBoundaryConditions(double t)` to set external forcing inputs.

## How to Use

### Generate Java from CellML

```bash
cellml2fruitcropxl --cellml model.cellml --package org.fruitcropxl.cellml --output-dir gen/
```

This creates:
- `gen/org/fruitcropxl/cellml/AbstractCellmlModel.java` (shared base)
- `gen/org/fruitcropxl/cellml/<ModelName>.java` (abstract model with named fields)

### Create a Simulation Subclass

The generated model is abstract. The user must implement `applyBoundaryConditions`:

```java
public class MyModelSim extends MyModel {
    @Override
    protected void applyBoundaryConditions(double t) {
        // Set external inputs at time t
        // Examples: pasfls, u_stem_water, VPD, phloem concentrations
        // These are PUBLIC fields on the generated model — access them directly
    }
}
```

### Compile and Run

```bash
javac -cp <commons-math3.jar> gen/org/fruitcropxl/cellml/*.java MySim.java
java -cp .:<commons-math3.jar> MySim
```

## Key Patterns

### 1. The `applyBoundaryConditions` Hook

Called by `computeDerivatives` BEFORE `computeComputedConstants()`. This means:
- Set your forcing inputs in `applyBoundaryConditions`
- The model's `computeComputedConstants` will re-derive dependent constants
- The model's `computeRates` will use the updated values

```java
@Override
protected void applyBoundaryConditions(double t) {
    // These are PUBLIC fields on the generated model
    pasfls = someInterpolation(t);
    u_stem_water = climateData.getStemWaterPotential(t);
}
```

### 2. Named Field Access

All state, rate, constant, and algebraic variables are public fields:

```java
MyModelSim model = new MyModelSim();
model.mSuc = 0.05;           // set initial state
model.ka0 = 0.06;            // override a parameter
model.pasfls = 0.01;         // set forcing (or do it in applyBoundaryConditions)

// After integration, read results:
double sucrose = model.mSuc;
double glucoseFlux = model.flux_k0;
```

### 3. Parameter Override

Use `setParameter(name, value)` for named parameter access:

```java
model.setParameter("ka0", 0.0566);
model.setParameter("kb0", 0.000418);
```

### 4. Piecewise Functions

CellML `<piecewise>` elements are translated to Java ternary expressions:

```java
// In the generated model:
theta_sym = ((ratio_sym < 0.0) ? 0.0 : ((ratio_sym > 1.0) ? 1.0 : ratio_sym));
W_kg = ((q_total_vol * rho_water > 1e-09) ? (q_total_vol * rho_water) : 1e-09);
```

These are readable and debuggable — set a breakpoint on any ternary to inspect the condition.

## Common Tasks

### Task: Run a simulation with CSV forcing data

1. Read the CSV (time + forcing columns) in your subclass constructor
2. Build interpolation functions
3. In `applyBoundaryConditions(t)`, interpolate and set the forcing fields

See `examples/Jfruit2OracleRealTest.java` for a complete example.

### Task: Override optimized parameters

```java
public class MyModelSim extends MyModel {
    public MyModelSim() {
        super();
        // Override parameters after super() (which sets CellML defaults)
        setParameter("ka0", 0.0566);
        setParameter("kb0", 0.000418);
    }
    
    @Override
    protected void applyBoundaryConditions(double t) {
        // ...
    }
}
```

### Task: Use a different integrator

```java
// RK4 (fixed step):
FirstOrderIntegrator integrator = new ClassicalRungeKuttaIntegrator(1.0/24.0); // 1-hour step in days

// Adaptive Dormand-Prince (RK45):
FirstOrderIntegrator integrator = new DormandPrince54Integrator(1e-10, 1.0/24.0, 1e-8, 1e-6);
```

## What NOT to Do

- **Do NOT edit the generated model class** — it's auto-generated. Re-run the tool if the CellML changes.
- **Do NOT implement boundary conditions in the generated class** — that's what `applyBoundaryConditions` is for, and the generated class is abstract.
- **Do NOT hardcode forcing data in the generated class** — load it in your subclass.

## File Layout

```
cellml2fruitcropxl/
  pyproject.toml                  ← Package metadata
  README.md                       ← This file's companion (full docs)
  AGENTS.md                       ← This file
  src/cellml2fruitcropxl/
    __init__.py
    cli.py                        ← CLI entry point
    metadata.py                   ← libcellml metadata extraction
    emitter.py                    ← AST → Java emitter (mirrors casadi_compiler)
    generator.py                  ← Java file generation
  examples/                       ← Example user subclasses
  tests/
    verify.sh                     ← End-to-end verification
    gen/                          ← Generated Java output
```
