# Benjamin Tiffon-Terrade grape berry acid dataset

## Purpose

This package recovers and standardizes the surviving experimental and literature observations assembled for Benjamin Tiffon-Terrade's 2018 Master 2 report, *Model development to predict organic acid accumulation over grape berry development*. It is intended to support reproducible reconstruction of that analysis and later, separately authorized calibration or validation work for a mechanistic grape berry acid model and FruitCropXL/JFruit2 coupling.

The historical archive outside `acid_model_dataset/` is unchanged. `raw/` contains checksum-traceable copies of only the files judged relevant to the four target studies, Benjamin's analysis, and one explicitly excluded Cabernet Sauvignon branch from the Bobeica study. Numerical gaps were not filled or interpolated.

## Relationship to Benjamin's model

Benjamin's development sequence distinguishes drivers, intermediate inputs, and targets:

1. measured pH plus temperature were used to estimate the malate model;
2. measured pH plus temperature were used to estimate the tartrate model;
3. malate, tartrate, temperature, and potassium were used to estimate the pH model;
4. the coupled model used temperature and potassium as external drivers and predicted pH, malate, and tartrate together.

Accordingly, `model_role` never labels every berry trait as a model input. Temperature and potassium are `final_model_driver`; pH is `intermediate_model_input_and_calibration_target`; malate and tartrate are `calibration_target`; berry mass, sugars, secondary metabolites, and other ions are `contextual_trait`.

Canonical conversions use current molar masses (malic acid 134.0874 g mol-1, tartaric acid 150.087 g mol-1, K 39.0983 g mol-1). Soyer acids are canonically converted from the author workbook's meq L-1 values by dividing by 2000 for diprotic malic/tartaric acid. `acid_model_inputs.csv` also retains Benjamin's cleaned g L-1 values and separate `*_benjamin2018` results calculated with his rounded denominators (134, 150, and 39) for strict historical comparison.

## Source experiments

### Kliewer and Lider — Cardinal and Pinot Noir

The recovered table contains 40 digitized treatment means: two cultivars, two prescribed day temperatures (20 and 30 °C), two light regimes (high and low), and five weekly stages after veraison. Night temperature was prescribed at 15 °C. Berry fresh mass, Brix, pH, malate, tartrate, and total acidity are present; potassium and berry dry mass are absent. The environmental values are chamber set-points, not an observed hourly climate record. The workbook identifies Figures 2–3 on journal page 767; its sheet-level cultivar annotations are swapped, so cultivar identity was resolved against the figure/table values and explicit correction note.

Benjamin's report calls this dataset “Kliewer et al. (1965)”. That citation is not supported by the recovered design. The local 1965 paper reports acid development in eight cultivars and does not describe the Cardinal/Pinot Noir controlled-temperature experiment. The digitization workbook, treatment design, and the relevant article within a compiled scan instead identify Kliewer and Lider (1970), *Effects of Day Temperature and Light Intensity on Growth and Composition of Vitis vinifera L. Fruits*. The compiled scan also contains related 1971 and 1973 Kliewer papers, but the workbook's numerical locator is the 1970 Figures 2–3. Both the 1965 paper and compiled scan are retained so the discrepancy remains auditable. These data supported intermediate acid-model work but not the final coupled model because potassium was unavailable.

### Soyer and Molot — Cabernet Sauvignon

The recovered LAB experiment contains 117 rows: K0, K60, and K120 (0, 60, and 120 kg K2O ha-1 yr-1), 13 sampling dates in 1990, and three replicates. It contains berry fresh mass, pH, malate, tartrate, potassium, soluble sugar, derived Brix, titratable acidity, calcium, and magnesium. Berry dry mass is absent. Only a temperature value historically joined to each sampling date survives; it is not treated as a replicate-level measurement or a complete climate series.

The original numerical workbook and Benjamin's cleaned model table agree on the experiment structure. Two distinct 1993 records are verifiable: the CIVB technical-day item cited by Benjamin, *Fertilisation potassique et acidité des moûts. Évolution durant la maturation des raisins*, pp. 16–20, and the journal article *Fertilisation potassique et composition des moûts. Évolution durant la maturation des raisins*, *Le Progrès Agricole et Viticole* 110(8), 174–177. The surviving numerical files do not prove which publication presentation was digitized, so both are retained in the bibliography. No DOI was verified for either.

### Bobeica et al. — Sangiovese

The Sangiovese source:sink experiment contains 76 replicate-level rows for 3L and 12L treatments over 14 days-after-flowering stages. It includes fresh berry mass, pH, Brix, malate, tartrate, potassium (72 of 76 rows), total acidity, calculated hexose, anthocyanin, berry number per vine, and berry/sugar/carbon aggregates; berry dry mass is absent. The original workbook contains additional amino-acid and anthocyanin fractions that remain in `raw/` but are not promoted because their units or interpretation have not yet been resolved. Benjamin's final script excludes DAF 105, the four rows without potassium.

The climate workbook supplies 73 daily records of air temperature, vapour-pressure deficit, and direct/diffuse PAR. Historical Cabernet Sauvignon digitizations from the same publication are copied under `raw/bobeica_2015/historical_cabernet_digitization_excluded/` for provenance but are not merged with the target Sangiovese experiment.

### Etchebarne et al. — Grenache

The 2007 Grenache experiment has six original treatments: A1 (irrigated, 10 leaves), A2 (irrigated, 5 leaves), B1 (non-irrigated, 10 leaves), B2 (non-irrigated, 5 leaves), CI (irrigated, 18-leaf control), and CNI (non-irrigated, 18-leaf control). Early sampling rows were pooled as A1/A2/B1/B2, A1/A2, or B1/B2 and are retained under explicit pooled identifiers rather than assigned to a treatment. The 184 recovered rows contain pH, malate, tartrate, potassium and other cations, berry fresh/dry mass and volume, water content, Brix, sugar/hexose, titratable acidity, and cluster traits. A daily INRA station series provides temperature, humidity, rainfall, radiation, evapotranspiration, and wind variables.

The exact intended four-treatment subset is A1, A2, B1, and B2: Benjamin states that four of six treatments were used because potassium was available for them. However, the final script reads the 164-row `Grenache7.2.csv`, which removes rows lacking both acids or K but still includes pooled early samples and terminal CI/CNI observations. Figure 8 is also captioned “Grenache all treatments.” `benjamin_declared_subset` and `benjamin_final_script_included` therefore record these two different facts; neither is silently substituted for the other.

The correct author spelling is Flor Etchebarne. Benjamin's narrative uses “Etchebane”; the historical spelling is preserved in notes, while bibliographic metadata uses Etchebarne.

## Package structure

- `dataset_catalog.csv`: one row per study × target cultivar dataset (five cultivars).
- `source_manifest.csv`: checksum-backed mapping from every copied source to a surviving historical original.
- `raw/`: unchanged relevant source copies, publications, scripts, and historical model inputs.
- `intermediate/converted/`: deterministic normalized tables produced by the scripts.
- `intermediate/digitized/`: reserved for any future, explicitly labelled re-digitization; currently empty.
- `curated/observations_long.csv`: one standardized non-missing variable observation per row.
- `curated/acid_model_inputs.csv`: one row per experimental sampling unit, including explicit missing core fields and measured/source flags.
- `curated/climate_long.csv`: actual daily climate where available, the explicitly uncertain Soyer sampling-date temperature join, and prescribed Kliewer regimes; missing daily values remain explicit rows.
- `curated/treatments.csv`: quantitative treatment definitions, intended Benjamin inclusion, and exclusions.
- `curated/sampling_events.csv`: original time axes without converting between flowering, veraison, or calendar bases.
- `scripts/`: inventory, import, conversion, build, and QC code.
- `qc/reports/`: complete inventory, counts, missingness, duplicate output, and QC summary.
- `qc/figures/`: treatment/time-series diagnostic plots, including an explicit “not available” potassium panel for Kliewer.
- `references/bibliography.bib`: verified citations and documented citation conflicts.

Field definitions and variable-specific interpretation are in `DATA_DICTIONARY.md`.

## Reproduction

Run from any working directory with R 4.x, `readxl`, and `ggplot2` installed:

```bash
Rscript "scripts/01_inventory.R"
Rscript "scripts/02_import_and_clean.R"
Rscript "scripts/03_unit_conversion.R"
Rscript "scripts/04_build_curated_tables.R"
Rscript "scripts/05_qc_plots.R"
```

When invoked from the repository root, prefix each command with `paper_writing/2018_1_acid model/acid_model_dataset/`. The scripts explicitly decode R's `~+~` representation of spaces in `--file` paths.

## Units and conversions

Every standardized observation retains `value_original` and `unit_original`. Acids reported in g L-1 are divided by their molar mass; Kliewer g per 100 mL values are first multiplied by 10; Soyer meq L-1 values are divided by 2000 for diprotic acids; K in g L-1 or mg L-1 is converted to mol L-1 after the appropriate mass scaling; and Kelvin is calculated as °C + 273.15. pH is dimensionless. Fresh and dry mass remain g berry-1. Source-specific sugar and titratable-acidity bases are retained rather than forced into a common chemical basis.

No mass-per-fresh-mass value was converted to mol L-1, and no density or vacuolar-volume assumption was introduced. Benjamin's thermodynamic interpretation of berry quantities as vacuolar concentrations is a modelling assumption, not an observed conversion, and is not embedded in `observations_long.csv`.

## Provenance grades

- A — original numerical data file;
- B — numerical supplementary or publication table;
- C — values recovered from historical analysis/model-input files;
- D — Benjamin-era PlotDigitizer values;
- E — newly digitized values (none created in this package);
- F — publication or inferred metadata only.

The observation table records the most immediate numerical source. A publication may therefore be grade F in the file manifest while its associated original workbook is grade A. Inferred treatment or citation metadata is never emitted as a measured observation.

## Limitations

- No original author-supplied Kliewer/Lider numerical table was found; its observations remain historical digitizations with unknown digitization error and no error bars.
- Kliewer potassium is genuinely absent, so those cultivars cannot drive Benjamin's final coupled model without new independent data.
- Soyer has no recovered full weather series, berry dry mass, or verified DAF/veraison axis. The retained sampling-date temperature join lacks station and aggregation metadata and requires further source recovery.
- Several Bobeica workbook variables have unresolved units; only interpretable fields are curated. Potassium is missing at DAF 105.
- Grenache early samples were pooled and cannot be separated retrospectively. Acid and K missingness produces a 164-row final-script subset, not a clean four-treatment-only table.
- Soyer and some historical Grenache/Bobeica columns lack measurement-method and error metadata. Means, SD/SE, and sample-size fields remain blank unless explicitly supplied.
- Climate data are not equivalent across studies. Prescribed regimes, sampling-date joins, and observed daily weather are explicitly separated. Bobeica has 13 missing daily values per retained climate variable; Etchebarne's 2007 evapotranspiration column is entirely blank although the workbook defines it.
- The datasets are useful for empirical calibration and response comparisons, but they do not by themselves identify intracellular fluxes, transport mechanisms, vacuolar volume, or causal whole-plant coupling.

## Future FruitCropXL/JFruit2 use

The curated core fields can support a later, separately reviewed acid-model calibration and comparisons of temperature, potassium, source:sink, and water-supply responses. Berry mass/volume and sugar traits provide possible linkage points to JFruit2 growth and carbon modules; daily Bobeica and Etchebarne climate can support temporal forcing checks. Such work should preserve cultivar/study-specific measurement bases, define calibration and validation partitions before fitting, and avoid treating co-measured responses as proof of an unmeasured mechanism.
