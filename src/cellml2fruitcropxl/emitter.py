"""emitter.py — Java expression emitter (AST → Java with named fields).

Mirrors casadi_compiler.py's CasadiTransformer:
- visit_Subscript converts states[i]/rates[i]/variables[i] to named fields.
- visit_Call converts exp()/math.exp to Math.exp, pow to Math.pow.
- visit_IfExp converts Python ternary to Java ternary (for piecewise functions).
"""
import ast
import math


class JavaEmitter:
    """Walks a Python AST expression node and emits a Java expression string."""

    def __init__(self, state_info, var_info):
        self.state_info = state_info
        self.var_info = var_info
        self.state_names = [s["name"] for s in state_info]
        self.var_names = [v["name"] for v in var_info]

    def emit_expr(self, node):
        """Recursively emit a Java expression string from a Python AST node."""
        if isinstance(node, ast.Constant):
            val = node.value
            if isinstance(val, bool):
                return "true" if val else "false"
            if isinstance(val, int):
                return str(val) + ".0"
            if isinstance(val, float):
                return repr(val)
            return str(val)

        elif isinstance(node, ast.Name):
            return node.id

        elif isinstance(node, ast.Subscript):
            # KEY TRANSFORMATION (mirrors CasadiTransformer.visit_Subscript)
            arr_name = node.value.id if isinstance(node.value, ast.Name) else None
            idx = self._get_index(node.slice)
            if arr_name == "states" and idx is not None and idx < len(self.state_names):
                return self.state_names[idx]
            elif arr_name == "rates" and idx is not None and idx < len(self.state_names):
                return f"d_{self.state_names[idx]}_dt"
            elif arr_name == "variables" and idx is not None and idx < len(self.var_names):
                return self.var_names[idx]
            return f"{arr_name}[{idx}]"

        elif isinstance(node, ast.BinOp):
            left = self.emit_expr(node.left)
            right = self.emit_expr(node.right)
            op = self._binop_to_java(node.op)
            return f"({left} {op} {right})"

        elif isinstance(node, ast.UnaryOp):
            if isinstance(node.op, ast.USub):
                return f"(-{self.emit_expr(node.operand)})"
            elif isinstance(node.op, ast.UAdd):
                return f"(+{self.emit_expr(node.operand)})"
            return self.emit_expr(node.operand)

        elif isinstance(node, ast.Call):
            func = node.func
            if isinstance(func, ast.Name):
                fname = func.id
                args = [self.emit_expr(a) for a in node.args]
                # libcellml comparison helpers (from piecewise → ternary)
                compare_funcs = {
                    "gt_func": ">", "lt_func": "<",
                    "ge_func": ">=", "le_func": "<=",
                    "eq_func": "==", "ne_func": "!=",
                }
                if fname in compare_funcs and len(args) == 2:
                    return f"({args[0]} {compare_funcs[fname]} {args[1]})"
                math_funcs = {
                    "exp": "Math.exp", "log": "Math.log", "log10": "Math.log10",
                    "pow": "Math.pow", "sqrt": "Math.sqrt",
                    "sin": "Math.sin", "cos": "Math.cos", "tan": "Math.tan",
                    "asin": "Math.asin", "acos": "Math.acos", "atan": "Math.atan",
                    "floor": "Math.floor", "ceil": "Math.ceil",
                    "fabs": "Math.abs", "abs": "Math.abs",
                    "max": "Math.max", "min": "Math.min",
                }
                if fname in math_funcs:
                    return f"{math_funcs[fname]}({', '.join(args)})"
                return f"{fname}({', '.join(args)})"
            elif isinstance(func, ast.Attribute) and isinstance(func.value, ast.Name):
                if func.value.id == "math":
                    attr = "power" if func.attr == "pow" else func.attr
                    args = [self.emit_expr(a) for a in node.args]
                    return f"Math.{attr}({', '.join(args)})"
            args = [self.emit_expr(a) for a in node.args]
            return f"/*TODO:call*/({', '.join(args)})"

        elif isinstance(node, ast.IfExp):
            # Python ternary `a if cond else b` -> Java `cond ? a : b`
            # This handles libcellml's piecewise → ternary translation.
            test = self.emit_expr(node.test)
            body = self.emit_expr(node.body)
            orelse = self.emit_expr(node.orelse)
            return f"({test} ? {body} : {orelse})"

        elif isinstance(node, ast.Compare):
            left = self.emit_expr(node.left)
            ops_map = {
                ast.Eq: "==", ast.NotEq: "!=", ast.Lt: "<", ast.LtE: "<=",
                ast.Gt: ">", ast.GtE: ">=", ast.Is: "==", ast.IsNot: "!=",
            }
            parts = [left]
            for op, comp in zip(node.ops, node.comparators):
                op_str = ops_map.get(type(op), "?")
                parts.append(f" {op_str} ")
                parts.append(self.emit_expr(comp))
            return f"({''.join(parts)})"

        elif isinstance(node, ast.BoolOp):
            # Python `a and b` → Java `(a && b)`, `a or b` → `(a || b)`
            java_op = "&&" if isinstance(node.op, ast.And) else "||"
            vals = [self.emit_expr(v) for v in node.values]
            return f"({' {} '.format(java_op).join(vals)})"

        return f"/*TODO:{type(node).__name__}*/"

    def emit_stmt(self, node):
        """Emit a Java statement from a Python AST Assign node."""
        if isinstance(node, ast.Assign):
            target = self.emit_expr(node.targets[0])
            value = self.emit_expr(node.value)
            return f"        {target} = {value};"
        elif isinstance(node, ast.Expr):
            return f"        {self.emit_expr(node.value)};"
        return f"        // TODO: {type(node).__name__}"

    def _get_index(self, slice_node):
        if isinstance(slice_node, ast.Constant):
            return slice_node.value
        if hasattr(slice_node, "value"):
            if isinstance(slice_node.value, ast.Constant):
                return slice_node.value.value
            if isinstance(slice_node.value, int):
                return slice_node.value
        return None

    def _binop_to_java(self, op):
        return {
            ast.Add: "+", ast.Sub: "-", ast.Mult: "*", ast.Div: "/",
            ast.Mod: "%",
        }.get(type(op), "?")
