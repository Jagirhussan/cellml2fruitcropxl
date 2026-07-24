"""metadata.py — Extract model metadata from a CellML file using libcellml's Analyser.

Mirrors casadi_compiler.py:extract_model_metadata — uses AnalyserVariable.Type
to classify each variable (CONSTANT, COMPUTED_CONSTANT, ALGEBRAIC, etc.).
"""
from libcellml import Parser, Analyser, AnalyserVariable


def extract_model_metadata(cellml_content):
    """Parse CellML and return state_info, var_info.

    Each state_info entry: {"name", "units", "initial_value"}
    Each var_info entry: {"name", "units", "type", "initial_value"}
    """
    parser = Parser()
    parser.setStrict(False)
    model = parser.parseModel(cellml_content)
    analyser = Analyser()
    analyser.analyseModel(model)
    if analyser.errorCount() > 0:
        errors = [analyser.issue(i).description() for i in range(analyser.errorCount())]
        raise ValueError(f"CellML analysis errors: {errors}")

    model_data = analyser.model()

    state_info = []
    for i in range(model_data.stateCount()):
        v = model_data.state(i).variable()
        state_info.append({
            "name": v.name(),
            "units": v.units().name() if v.units() else "dimensionless",
            "initial_value": v.initialValue(),
        })

    type_map = {
        AnalyserVariable.Type.CONSTANT: "Constant",
        AnalyserVariable.Type.COMPUTED_CONSTANT: "ComputedConstant",
        AnalyserVariable.Type.ALGEBRAIC: "Algebraic",
        AnalyserVariable.Type.VARIABLE_OF_INTEGRATION: "VOI",
        AnalyserVariable.Type.EXTERNAL: "External",
    }

    var_info = []
    for i in range(model_data.variableCount()):
        av = model_data.variable(i)
        var = av.variable()
        v_type = av.type()
        type_str = type_map.get(v_type, "Unknown")
        var_info.append({
            "name": var.name(),
            "units": var.units().name() if var.units() else "dimensionless",
            "type": type_str,
            "initial_value": var.initialValue(),
        })

    return state_info, var_info


def get_cellml_model_name(cellml_path):
    """Extract the model name from the CellML XML <model name="..."> attribute."""
    import xml.etree.ElementTree as ET
    tree = ET.parse(cellml_path)
    root = tree.getroot()
    name = root.get("name", root.get("{http://www.cellml.org/cellml/2.0#}name", "cellml_model"))
    return name


def to_java_class_name(model_name):
    """Convert a CellML model name to a valid Java class name.
    e.g. 'jfruit2_oracle' -> 'Jfruit2Oracle', 'sugar_ebm_superset' -> 'SugarEbmSuperset'
    """
    parts = model_name.replace("-", "_").split("_")
    return "".join(p[:1].upper() + p[1:] for p in parts if p)


def package_to_path(package):
    """Convert a Java package name to a directory path."""
    return package.replace(".", "/")
