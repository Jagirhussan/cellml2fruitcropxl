/*
 * EBMExample.java — Run the Fruit_Sugar_EBM simulation with real boundary conditions.
 *
 * Uses DormandPrince54Integrator (adaptive RK45) with tight tolerances.
 * If the system is too stiff for explicit methods, this will show divergence.
 *
 * Output CSV is compared against the Python Radau reference.
 */
package org.fruitcropxl.cellml;

import java.util.Arrays;

import org.apache.commons.math3.ode.FirstOrderIntegrator;
import org.apache.commons.math3.ode.nonstiff.DormandPrince54Integrator;

public class EBMExample {

    public static void main(String[] args) throws Exception {
        String workspace = args.length > 0 ? args[0] : "/hpc/rjag008/BSI/FGMXL";

        // 1. Create the simulation model with ALL boundary conditions
        System.err.println("Loading data and setting up boundary conditions...");
        SugarEbmSupersetSim model = new SugarEbmSupersetSim(workspace);
        double[] times = model.getTimes();
        int nSteps = times.length;

        System.err.println("Initial states: " + Arrays.toString(model.getStates()));
        System.err.println("t_span: " + times[0] + " to " + times[nSteps - 1] + " (" + nSteps + " points)");

        // 2. Create integrator — adaptive Dormand-Prince with tight tolerances
        // NOTE: Python uses Radau (implicit stiff solver). commons-math3 has no stiff solver.
        // We try Dormand-Prince with very tight tolerances and small max step.
        FirstOrderIntegrator integrator = new DormandPrince54Integrator(
            1e-12, 1.0 / 24.0,  // minStep, maxStep (1 hour)
            1e-10, 1e-8);      // absTol, relTol

        // 3. Step-by-step integration
        double[] y = model.getStates();
        double[] yNext = new double[y.length];

        // libcellml state order
        String[] stateNames = model.getStateNames();
        System.out.println("tDays," + String.join(",", stateNames));

        for (int s = 0; s < nSteps; s++) {
            if (s > 0) {
                try {
                    integrator.integrate(model, times[s - 1], y, times[s], yNext);
                    double[] tmp = y; y = yNext; yNext = tmp;
                } catch (Exception e) {
                    System.err.println("Integration failed at step " + s + " (t=" + times[s] + "): " + e.getMessage());
                    // Output NaN for remaining steps
                    for (int j = 0; j < y.length; j++) y[j] = Double.NaN;
                }
            }
            // Output state at times[s]
            StringBuilder sb = new StringBuilder();
            sb.append(fmt(times[s]));
            for (int j = 0; j < y.length; j++) {
                sb.append(",").append(fmt(y[j]));
            }
            System.out.println(sb.toString());
        }

        // 4. Final validation
        System.err.println("\n--- Final State Totals ---");
        double totalSuc = model.getState("q_c_suc") + model.getState("q_v_suc");
        double totalSor = model.getState("q_c_sor");
        double totalGlu = model.getState("q_c_glu") + model.getState("q_v_glu") + model.getState("q_p_glu");
        double totalFru = model.getState("q_c_fru") + model.getState("q_v_fru");
        double totalSta = model.getState("q_p_sta");
        System.err.printf("Total_Suc=%.6f, Total_Sor=%.6f, Total_Glu=%.6f, Total_Fru=%.6f, Total_Sta=%.6f%n",
            totalSuc, totalSor, totalGlu, totalFru, totalSta);
    }

    static String fmt(double v) {
        if (Double.isNaN(v) || Double.isInfinite(v)) return "nan";
        return String.format("%.12g", v);
    }
}
