/*
 * Jfruit2OracleSim.java — User's concrete subclass of the generated Jfruit2Oracle.
 *
 * Implements applyBoundaryConditions(double t) with a constant pasfls forcing.
 * This class works in BOTH modes:
 *   - Standalone: pass to a commons-math3 FirstOrderIntegrator directly
 *   - FruitService: wrap in Jfruit2OracleFruitService(model, delta)
 */
package org.fruitcropxl.cellml;

public class Jfruit2OracleSim extends Jfruit2Oracle {

    public Jfruit2OracleSim() {
        super();
    }

    public Jfruit2OracleSim(double pasfls) {
        super();
        this.pasfls = pasfls;
    }

    @Override
    protected void applyBoundaryConditions(double t) {
        // The public pasfls field is the active boundary value. The constructor
        // sets a constant default; Jfruit2OracleFruitService.fromArray() may
        // replace it before each step. Do not overwrite it here, or a dynamic
        // service input would be lost before computeComputedConstants().
    }
}
