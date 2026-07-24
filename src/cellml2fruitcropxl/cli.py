"""cli.py — Command-line interface for cellml2fruitcropxl.

Usage:
    cellml2fruitcropxl --cellml <path> --package <pkg> [--output-dir <dir>] [--with-fruit-service]

Example:
    cellml2fruitcropxl --cellml model.cellml --package org.fruitcropxl.cellml --output-dir gen/
"""
import argparse
import os
import sys

from .metadata import get_cellml_model_name, to_java_class_name
from .generator import (
    generate_abstract_base, generate_model, generate_fruit_service,
    generate_model_interface, generate_fruit_service_api,
)


def main():
    parser = argparse.ArgumentParser(
        prog="cellml2fruitcropxl",
        description="CellML-to-Java tooling service for FruitCropXL. "
                    "Generates readable Java ODE models with named fields from CellML files.")
    parser.add_argument("--cellml", required=True,
                        help="Path to the CellML (.cellml) file")
    parser.add_argument("--package", default="org.fruitcropxl.cellml",
                        help="Java package name (default: org.fruitcropxl.cellml — plugs into FruitCropXL)")
    parser.add_argument("--output-dir", default=".",
                        help="Output directory root (default: current directory). "
                             "Files are created under <output-dir>/<package-path>/")
    parser.add_argument("--with-fruit-service", action="store_true",
                        help="Also generate Model.java, FruitServiceAPI.java, and a FruitService wrapper "
                             "(provides step-driven simulation; no jfruit2 dependency — interfaces are package-local)")
    parser.add_argument("--force", action="store_true",
                        help="Overwrite existing files")
    args = parser.parse_args()

    cellml_path = os.path.abspath(args.cellml)
    if not os.path.exists(cellml_path):
        print(f"Error: {cellml_path} not found", file=sys.stderr)
        sys.exit(1)

    model_name = get_cellml_model_name(cellml_path)
    class_name = to_java_class_name(model_name)

    print(f"CellML model: {model_name}")
    print(f"Java class:   {class_name} (abstract — user must subclass to implement applyBoundaryConditions)")
    print(f"Package:      {args.package}")
    print(f"Output dir:   {args.output_dir}")
    print()

    # 1. Generate the abstract base class (shared template).
    print("Generating AbstractCellmlModel.java...")
    ab_path = generate_abstract_base(args.package, args.output_dir)
    print(f"  -> {ab_path}")

    # 2. Generate the concrete model (named fields, abstract).
    print(f"Generating {class_name}.java...")
    model_path = generate_model(cellml_path, model_name, class_name, args.package, args.output_dir)
    print(f"  -> {model_path}")

    # 3. Optionally generate the FruitService interfaces + wrapper.
    if args.with_fruit_service:
        print("Generating Model.java (package-local interface)...")
        mi_path = generate_model_interface(args.package, args.output_dir)
        print(f"  -> {mi_path}")

        print("Generating FruitServiceAPI.java (package-local interface)...")
        fi_path = generate_fruit_service_api(args.package, args.output_dir)
        print(f"  -> {fi_path}")

        service_name = f"{class_name}FruitService"
        print(f"Generating {service_name}.java (concrete wrapper, no jfruit2 dependency)...")
        with open(cellml_path) as f:
            from .metadata import extract_model_metadata
            state_info, _ = extract_model_metadata(f.read())
        fs_path = generate_fruit_service(class_name, model_name, args.package, args.output_dir, state_info)
        print(f"  -> {fs_path}")

    print()
    print("Done.")
    print()
    print("NEXT STEPS:")
    print(f"  1. Compile with: javac -cp <commons-math3.jar> <package-path>/*.java")
    print(f"  2. Create a subclass of {class_name} and implement applyBoundaryConditions(double t):")
    print()
    print(f"     public class {class_name}Sim extends {class_name} {{")
    print(f"         @Override")
    print(f"         protected void applyBoundaryConditions(double t) {{")
    print(f"             // Set your external forcing inputs here")
    print(f"         }}")
    print(f"     }}")
    print()
    if not args.with_fruit_service:
        print("  (Use --with-fruit-service to also generate a FruitServiceAPI wrapper)")


if __name__ == "__main__":
    main()
