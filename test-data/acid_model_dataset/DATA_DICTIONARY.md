# Data dictionary

Blank fields mean unavailable or not applicable; they are not zeros. Boolean fields use `TRUE`/`FALSE`. Dates use ISO `YYYY-MM-DD`. Concentrations are juice/berry concentrations unless `measurement_basis` states otherwise.

## `curated/observations_long.csv`

Each row is one non-missing reported or recovered variable at one sampling unit. Missing core variables remain visible in `acid_model_inputs.csv` and the QC missingness report.

| Field | Definition |
|---|---|
| `study_id` | Stable experiment identifier; distinguishes the design-matched Kliewer/Lider source from Benjamin's 1965 citation. |
| `cultivar` | Canonical cultivar name. |
| `treatment_id` | Stable treatment key joining `treatments.csv`. |
| `treatment_group` | Broad treatment family or secondary grouping retained from the source. |
| `replicate` | Source replicate identifier; blank for digitized treatment means. |
| `sampling_event_id` | Unique study/treatment/time/replicate sampling-unit key. |
| `calendar_date` | Source or deterministically decoded date; blank when unavailable. |
| `year` | Experiment year where known; publication year is not substituted for an unknown experiment year. |
| `days_after_flowering` | Source DAF/JAA value. Etchebarne's JAA is days after anthesis and is retained without biological redefinition. |
| `days_after_veraison` | Source time in days after veraison; blank because no target dataset reports this exact basis. Kliewer/Lider weeks are not placed here. |
| `days_after_treatment` | Source time after treatment; blank because no trustworthy value was recovered. |
| `development_stage` | Human-readable original developmental position. |
| `variable_category` | Controlled group: `environment`, `model_direct_input`, `organic_acid`, `mineral`, `sugar`, `berry_growth`, `water_status`, `secondary_metabolite`, or `other_quality`. |
| `variable` | Canonical variable name defined below. |
| `model_role` | `final_model_driver`, `intermediate_model_input_and_calibration_target`, `calibration_target`, or `contextual_trait`. |
| `value` | Standardized numeric value. |
| `unit` | Canonical unit for `value`. |
| `value_original` | Numeric value as found in the immediate numerical source. |
| `unit_original` | Unit of `value_original`. |
| `measurement_basis` | Juice, berry, cluster, vine, regime, or other denominator/context. |
| `statistic` | Statistical status; normally `reported value`. A blank SD/SE means uncertainty was not recovered. |
| `n` | Sample size reported for this value; blank when unavailable. |
| `sd` | Reported standard deviation; blank when unavailable. |
| `se` | Reported standard error; blank when unavailable. |
| `source_id` | Key into `source_manifest.csv` for the immediate numerical source. |
| `source_page` | Publication/report page where a value was extracted; blank when not mapped point-by-point. |
| `source_table` | Source table identifier; blank when not applicable or unresolved. |
| `source_figure` | Source figure/panel identifier; blank when the surviving digitization does not preserve a reliable panel map. |
| `extraction_method` | `source_workbook_table`, `source_workbook_calculation`, `historical_analysis_table`, `historical_calculation`, or `historical_digitization`. |
| `digitization_quality` | Digitization uncertainty label. Historical PlotDigitizer precision was not reported, so it is `historical_precision_unquantified`. |
| `provenance_quality` | A–F grade defined in the README. |
| `is_measured` | `TRUE` for a source-reported biological measurement; `FALSE` for prescribed regimes, historical climate joins, or calculations. |
| `is_derived` | `TRUE` when calculated or aggregated rather than directly measured. |
| `benjamin_declared_subset` | Whether the sampling identity belongs to the subset Benjamin's text says was used. For Grenache this is only exact A1/A2/B1/B2 rows. |
| `benjamin_final_script_included` | Whether the row's sampling unit meets the actual historical final-input inclusion pattern. This differs from the declared Grenache subset. |
| `conversion` | Formula applied between original and canonical values; `none` means unchanged. |
| `notes` | Variable-level provenance, basis, or uncertainty note. |

## Canonical observation variables

| Canonical name | Description and biological interpretation | Canonical unit | Original units encountered | Status/conversion | Benjamin relevance and limitations |
|---|---|---|---|---|---|
| `air_temperature` | Temperature associated with a regime or sampling date. | `degree_C` | °C | Unchanged; not a berry replicate measurement. | Final driver. Kliewer is a prescribed day set-point; other observation rows are historical date joins. Use `climate_long.csv` for actual weather. |
| `berry_pH` | Berry/juice hydrogen-ion activity index. | dimensionless | dimensionless | Measured/reported or digitized; unchanged. | Intermediate acid-model input and calibration target; analytical protocol is incompletely documented. |
| `malate_concentration` | Malic-acid concentration. | `mol/L` | `g/100 mL`, `g/L`, `meq/L` | g/100 mL × 10 / 134.0874; g L-1 / 134.0874; Soyer meq L-1 / 2000. | Calibration target. Juice/vacuolar equivalence is not asserted. |
| `tartrate_concentration` | Tartaric-acid concentration. | `mol/L` | `g/100 mL`, `g/L`, `meq/L` | g/100 mL × 10 / 150.087; g L-1 / 150.087; Soyer meq L-1 / 2000. | Calibration target; same basis caution as malate. |
| `potassium_concentration` | Berry/juice K concentration. | `mol/L` | `g/L`, `mg/L` | g L-1 / 39.0983; mg L-1 / 1000 / 39.0983. | Final driver. Structurally absent for both Kliewer cultivars. Soyer canonical values use the higher-precision author workbook field. |
| `calcium_concentration` | Calcium concentration. | `mg/L` | `mg/L` | Unchanged. | Context for pH/ionic strength; not a final external driver in the curated role scheme. |
| `magnesium_concentration` | Magnesium concentration. | `mg/L` | `mg/L` | Unchanged. | Context for pH/ionic strength. |
| `sodium_concentration` | Sodium concentration. | `mg/L` | `mg/L` | Unchanged. | Contextual mineral only. |
| `berry_fresh_mass` | Mean fresh mass per berry. | `g/berry` | `g/berry` | Unchanged. | Fruit-growth linkage; no density conversion is applied. |
| `berry_dry_mass` | Mean dry mass per berry. | `g/berry` | `g/berry` | Unchanged. | Fruit-growth/carbon linkage; available only for Grenache in the recovered target datasets. |
| `berry_volume` | Mean berry volume. | `mL/berry` | `mL/berry` | Unchanged. | Potential concentration-volume link; available only for Grenache. |
| `berry_water_volume` | Water volume per berry. | `mL/berry` | `mL/berry` | Unchanged. | Grenache water/growth context. |
| `berry_water_fraction` | Water as percentage fresh mass. | `% FW` | `% FW` | Unchanged. | Grenache water-status context. |
| `berry_dry_matter_fraction` | Dry matter as percentage fresh mass. | `% FW` | `% FW` | Unchanged. | Grenache growth context. |
| `cluster_length` | Cluster length. | `cm` | `cm` | Unchanged. | Contextual Grenache cluster trait. |
| `cluster_fresh_mass` | Fresh cluster mass. | `g/cluster` | `g/cluster` | Unchanged. | Contextual source:sink trait. |
| `rachis_fresh_mass` | Rachis mass per cluster. | `g/cluster` | `g/cluster` | Unchanged. | Contextual cluster trait. |
| `berry_mass_per_cluster` | Total berry mass per cluster. | `g/cluster` | `g/cluster` | Unchanged. | Contextual source:sink trait. |
| `berry_number_per_cluster` | Berry count per cluster. | `count/cluster` | same | Unchanged. | Contextual source:sink trait. |
| `berry_number_per_vine` | Berry count per vine. | `count/vine` | same | Unchanged. | Bobeica vine-scale source:sink context. |
| `berry_carbon` | Calculated carbon in berries per vine. | `g C/vine` | same | Historical workbook calculation; formula not re-derived here. | Potential carbon-coupling context, not a direct acid-model input. |
| `brix` | Total soluble solids. | `degree_Brix` | same | Usually measured; Soyer's field is historically derived. | Sugar/ripening context. It is not assumed identical to g L-1 sugar. |
| `total_soluble_sugar` | Source-reported soluble sugar. | `g/L` | `g/L` | Unchanged. | Sugar-acid context; source-specific analytical basis retained. |
| `total_soluble_sugar_per_berry` | Sugar amount per berry. | `mg/berry` | same | Unchanged. | Grenache sugar accumulation context. |
| `hexose` | Glucose plus fructose/hexose concentration. | `g/L` | `g/L` | Measured for Grenache; calculated from Brix for Bobeica. | Sugar-acid context; derivation status must be respected. |
| `hexose_per_berry` | Hexose amount per berry. | `g/berry` or `mg/berry` | same | Source units retained because studies use different scales. | Contextual; units must be selected before cross-study analysis. |
| `hexose_per_vine` | Calculated hexose per vine. | `g/vine` | same | Source workbook calculation. | Vine-scale carbon context. |
| `total_acidity` | Source total-acidity measure. | `g/L` or `g tartaric_acid_equivalent/L` | `g/L`, `g tartaric acid equivalent/100 mL` | Kliewer equivalent values multiplied by 10; unresolved Bobeica chemical basis is unchanged. | Context only; not interchangeable across studies. |
| `titratable_acidity` | Titration-based acidity. | source-specific `g/L` or `g H2SO4 equivalent/L` | same | Unchanged. | Context only; acid-equivalent definitions differ. |
| `titratable_acidity_per_berry` | Titratable-acid amount per berry. | `mg/berry` | same | Unchanged. | Grenache amount basis, not concentration. |
| `anthocyanin` | Total anthocyanin on fresh-mass basis. | `mg/100 g FW` | same | Unchanged. | Bobeica ripening/quality context; not an acid-model input. |

## `curated/acid_model_inputs.csv`

One row is one sampling unit, including rows where a core variable is absent. Fields shared with `observations_long.csv` have the same meanings.

| Field | Definition / unit |
|---|---|
| `study_id`, `cultivar`, `treatment_id`, `replicate`, `sampling_event_id`, `calendar_date`, `year`, `days_after_flowering`, `days_after_veraison`, `weeks_after_veraison`, `development_stage` | Sampling identity and original time metadata. `weeks_after_veraison` is populated only for Kliewer/Lider; the day-based field remains blank. |
| `temperature_C` | Associated temperature in °C; prescribed or joined, not necessarily measured at the berry replicate. |
| `temperature_K` | Derived K = `temperature_C + 273.15`. |
| `berry_pH` | Dimensionless observed pH. |
| `malate_mol_L` | Canonical malate concentration, mol L-1. |
| `tartrate_mol_L` | Canonical tartrate concentration, mol L-1. |
| `potassium_mol_L` | Canonical K concentration, mol L-1. |
| `berry_fresh_mass_g` | Berry fresh mass, g berry-1. |
| `berry_dry_mass_g` | Berry dry mass, g berry-1. |
| `sugar_g_L` | Source-reported soluble sugar, g L-1; blank when only Brix/hexose exists. |
| `brix` | Total soluble solids, °Brix. |
| `temperature_source`, `pH_source`, `malate_source`, `tartrate_source`, `potassium_source` | Immediate numerical `source_id`; blank when unavailable. |
| `temperature_measured`, `pH_measured`, `malate_measured`, `tartrate_measured`, `potassium_measured` | Measurement flags. Joined/prescribed temperature is `FALSE`; blank core chemistry becomes `FALSE`. |
| `benjamin_declared_subset` | Narrative subset membership. |
| `benjamin_final_script_included` | Actual final-input inclusion pattern. |
| `malate_value_benjamin_source`, `malate_unit_benjamin_source` | Malate value/unit in Benjamin's cleaned model table (g L-1), kept separately from author-reported units. |
| `tartrate_value_benjamin_source`, `tartrate_unit_benjamin_source` | Tartrate value/unit in Benjamin's cleaned model table (g L-1). |
| `potassium_value_benjamin_source`, `potassium_unit_benjamin_source` | K value/unit in Benjamin's cleaned model table; g L-1 for Soyer and mg L-1 for Bobeica/Etchebarne. |
| `malate_mol_L_benjamin2018` | Reproduction value using g L-1 / 134. |
| `tartrate_mol_L_benjamin2018` | Reproduction value using g L-1 / 150. |
| `potassium_mol_L_benjamin2018` | Reproduction value using g L-1 / 39 after mg-to-g scaling where necessary. |

## `curated/treatments.csv`

| Field | Definition |
|---|---|
| `study_id`, `treatment_id`, `cultivar` | Treatment key. |
| `treatment_factor_1`, `factor_1_value`, `factor_1_unit` | Primary manipulation and quantitative/categorical value. |
| `treatment_factor_2`, `factor_2_value`, `factor_2_unit` | Crossed/secondary manipulation. |
| `leaf_number` | Leaves per shoot/cluster as supported by the source labels. |
| `leaf_to_fruit_ratio` | Quantitative ratio; blank because no consistent ratio was recovered. |
| `potassium_fertilization` | K2O application rate, kg K2O ha-1 yr-1. |
| `irrigation_level` | Irrigation identity. |
| `water_status` | Interpreted treatment water-status class; metadata, not a measured water-potential value. |
| `temperature_day`, `temperature_night` | Prescribed Kliewer/Lider temperatures, °C. |
| `used_by_benjamin` | Intended exact-treatment use based on narrative evidence. |
| `exclusion_reason` | Reason an exact or pooled treatment is outside the declared subset, including contradictory script evidence. |
| `notes` | Full biological treatment definition and aliases. |

## `curated/sampling_events.csv`

| Field | Definition |
|---|---|
| `study_id`, `cultivar`, `treatment_id`, `replicate`, `sampling_event_id` | Sampling key. |
| `calendar_date`, `year` | Calendar metadata where recoverable. |
| `days_after_flowering`, `days_after_veraison`, `weeks_after_veraison`, `development_stage` | Original developmental time fields. Week values are never stored as days. |
| `days_after_fruit_set`, `days_after_treatment` | Reserved time bases; blank because required anchor dates were not recovered. |
| `phenological_stage` | Source-style human-readable stage. |
| `original_x_axis_value` | Numeric x-axis value used by the source dataset. |
| `original_x_axis_definition` | `weeks after veraison`, `day of year`, `days after flowering`, or `days after anthesis (JAA)`. |
| `notes` | Sampling-specific caution, notably pooled Grenache rows. |

## `curated/climate_long.csv`

Each row is one environmental variable at one temporal unit. Kliewer rows describe regimes; Soyer rows preserve an uncertain historical sampling-date join; Bobeica and Etchebarne rows are actual daily files. A blank `value` preserves an explicit missing daily record rather than implying zero.

| Field | Definition |
|---|---|
| `study_id`, `cultivar`, `treatment_id` | Experiment and optional treatment association. |
| `datetime` | Timestamp at subdaily resolution; blank because no retained series is subdaily. |
| `calendar_date`, `year`, `day_of_year` | Daily time key. |
| `days_after_flowering` | Derived only where the recovered daily series has an experiment anchor; use with documented caution. |
| `variable` | Climate variable name: prescribed day/night temperature, air temperature, VPD, direct/diffuse radiation, evapotranspiration, rainfall, humidity, or wind. |
| `value`, `unit` | Numeric value and source-supported unit. Etchebarne radiation is J cm-2 day-1 and wind is m s-1; Bobeica PAR is µmol m-2 s-1. |
| `temporal_resolution` | `daily` or `prescribed regime`. |
| `controlled_environment` | `TRUE` only for the Kliewer/Lider regime. |
| `is_measured` | `TRUE` for actual weather records; `FALSE` for prescribed values. |
| `is_derived` | Whether the climate value itself was derived; all current values are source values. |
| `source_id` | Manifest source. |
| `notes` | Regime/weather distinction and source caveats. |

## `dataset_catalog.csv`

| Field | Definition |
|---|---|
| `study_id`, `citation`, `cultivar` | Dataset identity. |
| `experiment_location`, `experiment_year`, `growing_environment` | Site/year/environment metadata; unresolved elements are stated rather than inferred. |
| `treatment_type`, `number_of_treatments`, `treatment_names` | Experimental design summary. Pooled Grenache sampling identities do not increase the six-treatment design count. |
| `sampling_start`, `sampling_end`, `number_of_sampling_events`, `developmental_time_definition` | Original sampling coverage. Event counts describe distinct time stages, not replicate rows. |
| `climate_available` | Type and resolution of environmental information. |
| `potassium_available`, `pH_available`, `malate_available`, `tartrate_available`, `sugar_available`, `berry_FW_available`, `berry_DW_available` | Dataset-level availability flags. |
| `other_traits_available` | Semicolon-separated summary of other curated traits. |
| `used_by_benjamin` | Whether Benjamin used the dataset, independent of individual-row subset flags. |
| `role_in_original_model` | Intermediate/final model use and exclusions. |
| `provenance_quality` | Available provenance grades, sometimes combined (for example A/C). |
| `notes` | Dataset-specific citation, missingness, or selection caution. |

## `source_manifest.csv`

| Field | Definition |
|---|---|
| `source_id` | Unique source key used by curated tables. |
| `study_id`, `citation`, `year`, `cultivar` | Source-level bibliographic association. |
| `local_original_path` | Historical source path with identical SHA-256 content. |
| `curated_copy_path` | Package-relative copied path. A different basename for the copied R workspace/history is explicitly mapped here. |
| `file_type` | Lowercase extension. |
| `role` | `publication`, `original_data`, `digitized_data`, `analysis_script`, or `model_input`. |
| `extraction_method` | `copied_unchanged`, `historical_analysis`, or `historical_digitization`. |
| `source_table`, `source_figure`, `source_page` | Point-extraction locator; blank where the file as a whole is the source or historical mapping is unresolved. |
| `notes` | Inclusion/exclusion and provenance caution. |
| `checksum` | SHA-256 checksum of the curated copy. |
| `provenance_quality` | A–F quality grade. |

## QC report fields

`observation_counts.csv` reports `study_id`, `cultivar`, `treatment_id`, `variable`, `unit`, and `n_observations`. `missingness_by_study_treatment_variable.csv` and its core-only copy `core_observation_counts.csv` add `n_sampling_units`, `n_available`, and `n_missing`. `climate_missingness.csv` reports the same availability distinction for every climate series and time grid. `variable_availability_by_study.csv` aggregates non-missing rows by dataset. `benjamin_selection_audit.csv` reports sampling-unit counts, declared-subset counts, actual final-script inclusion, complete coupled-model rows, and evidence notes. `duplicate_observations.csv` uses the full observation schema and should contain only its header after a passing run.
