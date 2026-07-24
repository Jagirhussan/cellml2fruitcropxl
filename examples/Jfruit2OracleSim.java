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

    private double pasflsValue = 0.01; // constant forcing [g/day]

    public Jfruit2OracleSim() {
        super();
    }

    public Jfruit2OracleSim(double pasfls) {
        super();
        this.pasflsValue = pasfls;
    }

    @Override
    protected void applyBoundaryConditions(double t) {
        // Set the external forcing input before the equations are evaluated.
        // This is called by computeDerivatives BEFORE computeComputedConstants,
        // so the derived constants (sugar_flux_g_d, in_Suc_d, in_Sor_d) will
        // reflect the updated pasfls value.
        pasfls = pasflsValue;
    }
}
