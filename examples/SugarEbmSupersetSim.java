/*
 * SugarEbmSupersetSim.java — User's simulation subclass with REAL boundary conditions.
 *
 * Implements applyBoundaryConditions(t) with ALL 6 forcing inputs:
 *   - u_atm_water (VPD from climate CSV)
 *   - u_stem_water (stem water potential from climate CSV)
 *   - u_sor_base (sorbitol unloading from target CSV pasfls)
 *   - x_phloem_suc_base (phloem sucrose from target CSV ctcs)
 *   - x_phloem_sor_base (phloem sorbitol from target CSV ctcs)
 *   - t_rip_base (ripening time from peak starch)
 *
 * Also injects 33 Julia-optimized parameters and sets compartment-split initial conditions.
 */
package org.fruitcropxl.cellml;

import java.io.*;
import java.util.*;

public class SugarEbmSupersetSim extends SugarEbmSuperset {

    // Interpolation data for boundary conditions
    private final double[] times, vpdArr, psiStemArr, uSorArr, xSucArr, xSorArr;
    private final double tRip;

    // Julia-optimized parameters (some log10-transformed)
    private static final double[] JULIA_OPT = {
        -0.35434409625690233, 3.3726295383085483, 0.20073150788368016, 1.8592776182626047,
        3.994737561958814, 3.3066462663561396, 0.06768570317112292, 1.7341114793893577,
        -0.9896735161653726, -2.378127976250085, -4.385421531702031, -4.389634797355308,
        -2.962096590750221, -3.6005648432466355, -0.579713170765682, -0.0013821288238073117,
        -1.1794921450154556, -2.0068107549492997, -7.407812286027083, -7.317754140198094,
        -5.9773125327925065, 0.742577018402146, 0.022798403096228895, 0.9998716192714016,
        2.6775191911920717, -10.967268253574161, 4.999780382502864, 0.10006929127132635,
        -10.003731465438795, -11.174424411236283, -12.589359338526004, 6.991387532020343,
        6.010554966668809
    };
    private static final String[] PARAM_NAMES = {
        "K_Suc_c", "K_Suc_v", "K_Sor_c", "K_Glu_c", "K_Glu_v",
        "K_Fru_c", "K_Fru_v", "K_Glu_p", "K_Sta_p",
        "k_INV", "k_SDH1", "k_SDH2", "k_ISO", "k_TSuc",
        "k_TGlu", "k_TFru", "k_TPGlu", "k_STA", "k_Resp", "k_Syn",
        "k_INV_v", "k_AMY_max", "r_AMY", "lambda_apo",
        "D_redox", "phi_W", "Y", "C_bg",
        "L_x", "L_p", "g_skin", "epsilon", "Pi_phloem_sap"
    };
    private static final Set<Integer> LINEAR_INDICES = new HashSet<>(Arrays.asList(22, 23, 27));

    public SugarEbmSupersetSim(String workspacePath) throws Exception {
        super();

        // --- Load target CSV ---
        String targetCsv = workspacePath + "/growth_r1_fw0.50_dm0.50_sugar_sorbitol_r1_2021_day34_mean_out.csv";
        List<String> targetLines = readAllLines(targetCsv);
        String[] targetHeader = targetLines.get(0).split(",");
        int colAgeD = indexOf(targetHeader, "age_d");
        int colAgeH = indexOf(targetHeader, "age_h");
        int colPasfls = indexOf(targetHeader, "pasfls");
        int colCtcs = indexOf(targetHeader, "ctcs");
        int colMSuc = indexOf(targetHeader, "mSuc");
        int colMSor = indexOf(targetHeader, "mSor");
        int colMGlu = indexOf(targetHeader, "mGlu");
        int colMFru = indexOf(targetHeader, "mFru");
        int colMSta = indexOf(targetHeader, "mSta");
        int colV = indexOf(targetHeader, "v");

        int nRows = targetLines.size() - 1;
        times = new double[nRows];
        double[] pasflsArr = new double[nRows];
        double[] ctcsArr = new double[nRows];
        double[] mSuc = new double[nRows], mSor = new double[nRows], mGlu = new double[nRows];
        double[] mFru = new double[nRows], mSta = new double[nRows];
        double[] vol = new double[nRows];

        for (int r = 0; r < nRows; r++) {
            String[] p = targetLines.get(r + 1).split(",");
            double ageD = Double.parseDouble(p[colAgeD].trim());
            double ageH = Double.parseDouble(p[colAgeH].trim());
            times[r] = ageD + ageH / 24.0;
            pasflsArr[r] = Double.parseDouble(p[colPasfls].trim());
            ctcsArr[r] = Double.parseDouble(p[colCtcs].trim());
            mSuc[r] = Double.parseDouble(p[colMSuc].trim());
            mSor[r] = Double.parseDouble(p[colMSor].trim());
            mGlu[r] = Double.parseDouble(p[colMGlu].trim());
            mFru[r] = Double.parseDouble(p[colMFru].trim());
            mSta[r] = Double.parseDouble(p[colMSta].trim());
            vol[r] = Double.parseDouble(p[colV].trim()) * 1e-6;
        }

        // --- Load climate CSV ---
        String climateCsv = workspacePath + "/climate_oracle.csv";
        List<String> climateLines = readAllLines(climateCsv);
        String[] climateHeader = climateLines.get(0).split(",");
        int colCAgeD = indexOf(climateHeader, "age_d");
        int colCAgeH = indexOf(climateHeader, "age_h");
        int colVPD = indexOf(climateHeader, "VPD_Pa");
        int colPsiStem = indexOf(climateHeader, "Psi_stem_Pa");

        vpdArr = new double[nRows];
        psiStemArr = new double[nRows];
        for (int r = 0; r < nRows; r++) {
            String[] p = climateLines.get(r + 1).split(",");
            vpdArr[r] = Double.parseDouble(p[colVPD].trim());
            psiStemArr[r] = Double.parseDouble(p[colPsiStem].trim());
        }

        // --- Compute derived boundary conditions (same as Python) ---
        double LAMBDA_S = 0.5, BSSRAT = 0.49, M_SOR = 182.17, M_SUC = 342.3;
        double denom = ((1.0 - LAMBDA_S) * M_SUC) + (LAMBDA_S * M_SOR);
        uSorArr = new double[nRows];
        xSucArr = new double[nRows];
        xSorArr = new double[nRows];
        for (int r = 0; r < nRows; r++) {
            double sugarFlux = pasflsArr[r] * 86400.0 * BSSRAT;
            uSorArr[r] = sugarFlux * ((LAMBDA_S * M_SOR) / denom) * (72.0 / M_SOR);
            double phloemTotal = ctcsArr[r] * 1000.0;
            xSucArr[r] = phloemTotal * 0.5;
            xSorArr[r] = phloemTotal * 0.5;
        }

        // --- Find t_rip (peak of mSta) ---
        int maxIdx = 0;
        for (int r = 1; r < nRows; r++) {
            if (mSta[r] > mSta[maxIdx]) maxIdx = r;
        }
        tRip = times[maxIdx];

        // --- Inject Julia-optimized parameters ---
        for (int i = 0; i < PARAM_NAMES.length; i++) {
            double val = LINEAR_INDICES.contains(i) ? JULIA_OPT[i] : Math.pow(10, JULIA_OPT[i]);
            setParameter(PARAM_NAMES[i], val);
        }
        computeComputedConstants();

        // --- Set initial conditions with compartment splitting (same as Python) ---
        // libcellml state order: [0]=q_total_vol, [1]=q_v_fru, [2]=q_c_fru, [3]=q_p_glu,
        //   [4]=q_v_glu, [5]=q_c_glu, [6]=q_c_sor, [7]=q_v_suc, [8]=q_c_suc, [9]=q_p_vol, [10]=q_p_sta
        setState("q_c_suc", mSuc[0] * 0.15);
        setState("q_v_suc", mSuc[0] * 0.85);
        setState("q_c_sor", mSor[0]);
        setState("q_c_glu", mGlu[0] * 0.02);
        setState("q_v_glu", mGlu[0] * 0.93);
        setState("q_p_glu", mGlu[0] * 0.05);
        setState("q_c_fru", mFru[0] * 0.02);
        setState("q_v_fru", mFru[0] * 0.98);
        setState("q_p_sta", mSta[0]);
        setState("q_total_vol", vol[0]);
        setState("q_p_vol", vol[0] * 0.95);
    }

    @Override
    protected void applyBoundaryConditions(double t) {
        // Set ALL 6 boundary conditions — interpolated from CSV data
        u_atm_water = interpLinear(times, vpdArr, t);
        u_stem_water = interpLinear(times, psiStemArr, t);
        u_sor_base = interpLinear(times, uSorArr, t);
        x_phloem_suc_base = interpLinear(times, xSucArr, t);
        x_phloem_sor_base = interpLinear(times, xSorArr, t);
        t_rip_base = tRip;
    }

    public double[] getTimes() { return times; }

    // --- Helpers ---
    private static List<String> readAllLines(String path) throws Exception {
        List<String> lines = new ArrayList<>();
        try (BufferedReader br = new BufferedReader(new FileReader(path))) {
            String line;
            while ((line = br.readLine()) != null) lines.add(line);
        }
        return lines;
    }

    private static int indexOf(String[] header, String name) {
        for (int i = 0; i < header.length; i++)
            if (header[i].trim().equals(name)) return i;
        throw new IllegalArgumentException("Column not found: " + name);
    }

    private static double interpLinear(double[] xs, double[] ys, double x) {
        if (x <= xs[0]) return ys[0];
        if (x >= xs[xs.length - 1]) return ys[ys.length - 1];
        int lo = 0, hi = xs.length - 1;
        while (hi - lo > 1) {
            int mid = (lo + hi) / 2;
            if (xs[mid] <= x) lo = mid; else hi = mid;
        }
        double frac = (x - xs[lo]) / (xs[hi] - xs[lo]);
        return ys[lo] + frac * (ys[hi] - ys[lo]);
    }
}
