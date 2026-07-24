"""cellml2fruitcropxl — CellML-to-Java tooling service for FruitCropXL.

Generates readable, debuggable Java ODE models from CellML 2.0 files,
with named fields (not opaque array indices), using the AST-transformation
approach from casadi_compiler.py's CasadiTransformer.

The generated model class extends AbstractCellmlModel and implements
FirstOrderDifferentialEquations (Apache Commons Math). The user creates
a subclass to implement applyBoundaryConditions(double t) — the hook
for setting external forcing inputs before the equations are evaluated.

Usage:
    cellml2fruitcropxl --cellml model.cellml --package org.fruitcropxl.cellml --output-dir gen/
"""
__version__ = "0.1.0"
