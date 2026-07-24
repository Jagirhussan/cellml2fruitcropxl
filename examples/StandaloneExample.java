/*
 * StandaloneExample.java — Simulate WITHOUT the Model/FruitService interface.
 *
 * Uses only Apache Commons Math (FirstOrderDifferentialEquations + ClassicalRungeKuttaIntegrator).
 * No Model interface, no FruitService wrapper — just the ODE model + integrator.
 *
 * This is the simplest path: the generated model implements FirstOrderDifferentialEquations,
 * and you drive it with any commons-math3 integrator.
 *
 * Compile: javac -cp <commons-math3.jar> gen/org/fruitcropxl/cellml/*.java examples/*.java
 * Run:     java -cp .:<commons-math3.jar> org.fruitcropxl.cellml.StandaloneExample
 */
package org.fruitcropxl.cellml;

import org.apache.commons.math3.ode.FirstOrderIntegrator;
import org.apache.commons.math3.ode.nonstiff.ClassicalRungeKuttaIntegrator;

public class StandaloneExample {

    static final String[] HEADER = {"tDays", "mSuc", "mSor", "mFru", "mGlu", "mSta", "mSyn"};

    public static void main(String[] args) {
        // 1. Create the user's concrete model (implements applyBoundaryConditions)
        Jfruit2OracleSim model = new Jfruit2OracleSim(0.01); // pasfls = 0.01 g/day

        // 2. Create the integrator (RK4, 1-hour step in days)
        FirstOrderIntegrator integrator = new ClassicalRungeKuttaIntegrator(1.0 / 24.0);

        // 3. Get initial states and set up integration
        double[] y = model.getStates();
        double[] yNext = new double[6];
        int nSteps = 100 * 24; // 100 days, hourly
        double stepDays = 1.0 / 24.0;

        System.out.println(String.join(",", HEADER));
        for (int s = 0; s < nSteps; s++) {
            double t0 = s * stepDays;
            double t1 = (s + 1) * stepDays;
            // integrate: y is input (initial state), yNext is output (final state at t1)
            integrator.integrate(model, t0, y, t1, yNext);
            // swap: y now holds the result for the next step
            double[] tmp = y; y = yNext; yNext = tmp;
            System.out.println(fmt(t1) + "," + fmt(y[0]) + "," + fmt(y[1]) + ","
                + fmt(y[2]) + "," + fmt(y[3]) + "," + fmt(y[4]) + "," + fmt(y[5]));
        }

        System.err.println("Standalone simulation complete: " + nSteps + " steps");
    }

    static String fmt(double v) {
        return String.format("%.12g", v);
    }
}
