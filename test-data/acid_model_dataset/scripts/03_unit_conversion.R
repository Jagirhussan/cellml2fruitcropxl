#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[1]) else "scripts/03_unit_conversion.R"
script_path <- gsub("~+~", " ", script_path, fixed = TRUE)
package_dir <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
converted_dir <- file.path(package_dir, "intermediate", "converted")

M_MALIC <- 134.0874
M_TARTARIC <- 150.087
M_K <- 39.0983

num <- function(x) suppressWarnings(as.numeric(as.character(x)))
yn <- function(x) ifelse(is.na(x), FALSE, as.logical(x))

schema <- c(
  "study_id", "cultivar", "treatment_id", "treatment_group", "replicate",
  "sampling_event_id", "calendar_date", "year", "days_after_flowering",
  "days_after_veraison", "days_after_treatment", "development_stage",
  "variable_category", "variable", "model_role", "value", "unit",
  "value_original", "unit_original", "measurement_basis", "statistic", "n",
  "sd", "se", "source_id", "source_page", "source_table", "source_figure",
  "extraction_method", "digitization_quality", "provenance_quality",
  "is_measured", "is_derived", "benjamin_declared_subset",
  "benjamin_final_script_included", "conversion", "notes"
)
observations <- setNames(as.data.frame(matrix(nrow = 0, ncol = length(schema))), schema)

make_meta <- function(x, study_id, event_id, daf = NA_real_, dav = NA_real_,
                      stage = NA_character_, treatment_group = NA_character_) {
  data.frame(
    study_id = study_id,
    cultivar = x$cultivar,
    treatment_id = x$treatment_id,
    treatment_group = treatment_group,
    replicate = if ("replicate" %in% names(x)) as.character(x$replicate) else NA_character_,
    sampling_event_id = event_id,
    calendar_date = if ("calendar_date" %in% names(x)) as.character(x$calendar_date) else NA_character_,
    year = if ("year" %in% names(x)) num(x$year) else NA_real_,
    days_after_flowering = daf,
    days_after_veraison = dav,
    days_after_treatment = NA_real_,
    development_stage = stage,
    stringsAsFactors = FALSE
  )
}

add_variable <- function(meta, original, variable, category, role, unit_original,
                         unit, convert = identity, basis = "berry or juice concentration",
                         source_id, method, quality, provenance,
                         measured = TRUE, derived = FALSE,
                         benjamin_declared = TRUE, benjamin_included = TRUE,
                         conversion = "none", notes = "", statistic = "reported value") {
  original <- num(original)
  keep <- !is.na(original)
  if (!any(keep)) return(invisible(NULL))
  z <- meta[keep, , drop = FALSE]
  z$variable_category <- category
  z$variable <- variable
  z$model_role <- role
  z$value <- convert(original[keep])
  z$unit <- unit
  z$value_original <- original[keep]
  z$unit_original <- unit_original
  z$measurement_basis <- basis
  z$statistic <- statistic
  z$n <- NA_real_
  z$sd <- NA_real_
  z$se <- NA_real_
  z$source_id <- source_id
  z$source_page <- NA_character_
  z$source_table <- NA_character_
  z$source_figure <- NA_character_
  z$extraction_method <- method
  z$digitization_quality <- quality
  z$provenance_quality <- provenance
  z$is_measured <- measured
  z$is_derived <- derived
  z$benjamin_declared_subset <- yn(benjamin_declared)[keep]
  z$benjamin_final_script_included <- yn(benjamin_included)[keep]
  z$conversion <- conversion
  z$notes <- notes
  observations <<- rbind(observations, z[, schema])
}

# Kliewer & Lider 1970 (misattributed as Kliewer et al. 1965 in Benjamin's report).
k <- read.csv(file.path(converted_dir, "kliewer_clean.csv"), check.names = FALSE,
              stringsAsFactors = FALSE)
k_event <- sprintf("KL70_%s_%s_WAV%s", gsub(" ", "_", k$cultivar),
                   k$treatment_id, k$week_after_veraison)
km <- make_meta(k, "kliewer_lider_1970", k_event,
                stage = paste0("week ", k$week_after_veraison, " after veraison"),
                treatment_group = k$light_regime)
ki <- k$benjamin_final_script_included
kd <- k$benjamin_declared_subset
add_variable(km, k$T, "air_temperature", "environment", "final_model_driver",
             "degree_C", "degree_C", source_id = "src_kliewer_benjamin_csv",
             method = "historical_digitization", quality = "historical_precision_unquantified",
             provenance = "D", measured = FALSE, benjamin_declared = kd, benjamin_included = ki,
             basis = "prescribed daytime chamber regime", notes = "Day set-point; night set-point was 15 degree C.")
add_variable(km, k$pH, "berry_pH", "model_direct_input", "intermediate_model_input_and_calibration_target",
             "dimensionless", "dimensionless", source_id = "src_kliewer_benjamin_csv",
             method = "historical_digitization", quality = "historical_precision_unquantified", provenance = "D",
             benjamin_declared = kd, benjamin_included = ki, basis = "berry/juice, publication figure")
add_variable(km, k$Malate / 10, "malate_concentration", "organic_acid", "calibration_target",
             "g/100 mL", "mol/L", function(v) v * 10 / M_MALIC,
             source_id = "src_kliewer_digitization_workbook",
             method = "historical_digitization", quality = "historical_precision_unquantified", provenance = "D",
             benjamin_declared = kd, benjamin_included = ki,
             conversion = "g/100 mL multiplied by 10, then divided by 134.0874 g/mol")
add_variable(km, k$Tartrate / 10, "tartrate_concentration", "organic_acid", "calibration_target",
             "g/100 mL", "mol/L", function(v) v * 10 / M_TARTARIC,
             source_id = "src_kliewer_digitization_workbook",
             method = "historical_digitization", quality = "historical_precision_unquantified", provenance = "D",
             benjamin_declared = kd, benjamin_included = ki,
             conversion = "g/100 mL multiplied by 10, then divided by 150.087 g/mol")
add_variable(km, k$FW, "berry_fresh_mass", "berry_growth", "contextual_trait",
             "g/berry", "g/berry", source_id = "src_kliewer_benjamin_csv", method = "historical_digitization",
             quality = "historical_precision_unquantified", provenance = "D", benjamin_declared = kd,
             benjamin_included = ki, basis = "fresh mass per berry")
add_variable(km, k$brix, "brix", "sugar", "contextual_trait", "degree_Brix", "degree_Brix",
             source_id = "src_kliewer_benjamin_csv", method = "historical_digitization",
             quality = "historical_precision_unquantified", provenance = "D", benjamin_declared = kd,
             benjamin_included = ki, basis = "juice soluble solids")
add_variable(km, k$total_acidity_g_100ml, "total_acidity", "organic_acid", "contextual_trait",
             "g tartaric_acid_equivalent/100 mL", "g tartaric_acid_equivalent/L", function(v) v * 10,
             source_id = "src_kliewer_digitization_workbook", method = "historical_digitization",
             quality = "historical_precision_unquantified", provenance = "D", benjamin_declared = kd,
             benjamin_included = ki, conversion = "multiplied by 10", basis = "juice")

# Soyer & Molot 1993 Cabernet Sauvignon K-fertilization experiment.
s <- read.csv(file.path(converted_dir, "soyer_clean.csv"), check.names = FALSE,
              stringsAsFactors = FALSE)
s_event <- sprintf("SO93_%s_DOY%s_R%s", s$treatment_id, s$day_of_year, s$replicate)
sm <- make_meta(s, "soyer_molot_1993", s_event,
                stage = paste0("day of year ", s$day_of_year),
                treatment_group = "potassium fertilization")
sd <- s$benjamin_declared_subset; si <- s$benjamin_final_script_included
add_variable(sm, s$T, "air_temperature", "environment", "final_model_driver", "degree_C", "degree_C",
             source_id = "src_soyer_benjamin_csv", method = "historical_analysis_table", quality = "not_assessed",
             provenance = "C", measured = FALSE, benjamin_declared = sd, benjamin_included = si,
             basis = "historical sampling-date climate join", notes = "Not an experimental replicate-level temperature measurement.")
add_variable(sm, s$pH, "berry_pH", "model_direct_input", "intermediate_model_input_and_calibration_target",
             "dimensionless", "dimensionless", source_id = "src_soyer_benjamin_csv", method = "historical_analysis_table",
             quality = "not_applicable", provenance = "C", benjamin_declared = sd, benjamin_included = si)
add_variable(sm, s$malate_meq_L, "malate_concentration", "organic_acid", "calibration_target", "meq/L", "mol/L",
             function(v) v / 2000, source_id = "src_soyer_original_workbook", method = "source_workbook_table",
             quality = "not_applicable", provenance = "A", benjamin_declared = sd, benjamin_included = si,
             conversion = "meq/L divided by 2 equivalents/mol and 1000 mmol/mol")
add_variable(sm, s$tartrate_meq_L, "tartrate_concentration", "organic_acid", "calibration_target", "meq/L", "mol/L",
             function(v) v / 2000, source_id = "src_soyer_original_workbook", method = "source_workbook_table",
             quality = "not_applicable", provenance = "A", benjamin_declared = sd, benjamin_included = si,
             conversion = "meq/L divided by 2 equivalents/mol and 1000 mmol/mol")
add_variable(sm, s$potassium_g_L_source, "potassium_concentration", "mineral", "final_model_driver", "g/L", "mol/L",
             function(v) v / M_K, source_id = "src_soyer_original_workbook", method = "source_workbook_table",
             quality = "not_applicable", provenance = "A", benjamin_declared = sd, benjamin_included = si,
             conversion = "g/L divided by 39.0983 g/mol")
add_variable(sm, s$FW, "berry_fresh_mass", "berry_growth", "contextual_trait", "g/berry", "g/berry",
             source_id = "src_soyer_benjamin_csv", method = "historical_analysis_table", quality = "not_applicable",
             provenance = "C", benjamin_declared = sd, benjamin_included = si, basis = "fresh mass per berry")
add_variable(sm, s$Hexose, "total_soluble_sugar", "sugar", "contextual_trait", "g/L", "g/L",
             source_id = "src_soyer_benjamin_csv", method = "historical_analysis_table", quality = "not_applicable",
             provenance = "C", benjamin_declared = sd, benjamin_included = si, basis = "juice")
add_variable(sm, s$brix, "brix", "sugar", "contextual_trait", "degree_Brix", "degree_Brix",
             source_id = "src_soyer_benjamin_csv", method = "historical_calculation", quality = "not_applicable",
             provenance = "C", measured = FALSE, derived = TRUE, benjamin_declared = sd, benjamin_included = si,
             conversion = "historical derived field; formula retained in source script")
add_variable(sm, s$total_acidity_g_H2SO4_eq_L, "titratable_acidity", "organic_acid", "contextual_trait",
             "g H2SO4 equivalent/L", "g H2SO4 equivalent/L", source_id = "src_soyer_original_workbook",
             method = "source_workbook_table", quality = "not_applicable", provenance = "A",
             benjamin_declared = sd, benjamin_included = si, basis = "juice")
add_variable(sm, s$magnesium_mg_L, "magnesium_concentration", "mineral", "contextual_trait", "mg/L", "mg/L",
             source_id = "src_soyer_original_workbook", method = "source_workbook_table", quality = "not_applicable",
             provenance = "A", benjamin_declared = sd, benjamin_included = si)
add_variable(sm, s$calcium_mg_L, "calcium_concentration", "mineral", "contextual_trait", "mg/L", "mg/L",
             source_id = "src_soyer_original_workbook", method = "source_workbook_table", quality = "not_applicable",
             provenance = "A", benjamin_declared = sd, benjamin_included = si)

# Bobeica et al. 2015 Sangiovese source:sink experiment.
b <- read.csv(file.path(converted_dir, "bobeica_clean.csv"), check.names = FALSE,
              stringsAsFactors = FALSE)
b_event <- sprintf("BO15_%s_DAF%s_R%s", b$treatment_id, b$DAF, b$replicate)
bm <- make_meta(b, "bobeica_2015_sangiovese", b_event, daf = num(b$DAF),
                stage = paste0("day ", b$DAF, " after flowering"), treatment_group = "leaf number")
bd <- b$benjamin_declared_subset; bi <- b$benjamin_final_script_included
add_variable(bm, b$T, "air_temperature", "environment", "final_model_driver", "degree_C", "degree_C",
             source_id = "src_bobeica_benjamin_csv", method = "historical_analysis_table", quality = "not_assessed",
             provenance = "C", measured = FALSE, benjamin_declared = bd, benjamin_included = bi,
             basis = "daily climate value joined to sampling date")
add_variable(bm, b$pH, "berry_pH", "model_direct_input", "intermediate_model_input_and_calibration_target",
             "dimensionless", "dimensionless", source_id = "src_bobeica_benjamin_csv", method = "historical_analysis_table",
             quality = "not_applicable", provenance = "C", benjamin_declared = bd, benjamin_included = bi)
add_variable(bm, b$Malate, "malate_concentration", "organic_acid", "calibration_target", "g/L", "mol/L",
             function(v) v / M_MALIC, source_id = "src_bobeica_benjamin_csv", method = "historical_analysis_table",
             quality = "not_applicable", provenance = "C", benjamin_declared = bd, benjamin_included = bi,
             conversion = "g/L divided by 134.0874 g/mol")
add_variable(bm, b$Tartrate, "tartrate_concentration", "organic_acid", "calibration_target", "g/L", "mol/L",
             function(v) v / M_TARTARIC, source_id = "src_bobeica_benjamin_csv", method = "historical_analysis_table",
             quality = "not_applicable", provenance = "C", benjamin_declared = bd, benjamin_included = bi,
             conversion = "g/L divided by 150.087 g/mol")
add_variable(bm, b$K., "potassium_concentration", "mineral", "final_model_driver", "mg/L", "mol/L",
             function(v) v / 1000 / M_K, source_id = "src_bobeica_benjamin_csv", method = "historical_analysis_table",
             quality = "not_applicable", provenance = "C", benjamin_declared = bd, benjamin_included = bi,
             conversion = "mg/L divided by 1000 and 39.0983 g/mol")
for (spec in list(
  list(b$FW, "berry_fresh_mass", "berry_growth", "g/berry", "g/berry", FALSE, "fresh mass per berry"),
  list(b$DW, "berry_dry_mass", "berry_growth", "g/berry", "g/berry", FALSE, "dry mass per berry"),
  list(b$brix, "brix", "sugar", "degree_Brix", "degree_Brix", FALSE, "juice soluble solids"),
  list(b$hexose_g_L, "hexose", "sugar", "g/L", "g/L", TRUE, "juice; calculated from Brix in source workbook"),
  list(b$total_acidity_g_L, "total_acidity", "organic_acid", "g/L", "g/L", FALSE, "juice; acid-equivalent basis unresolved"),
  list(b$total_anthocyanin_mg_100g_FW, "anthocyanin", "secondary_metabolite", "mg/100 g FW", "mg/100 g FW", FALSE, "berry fresh-mass basis"),
  list(b$berry_number_per_vine, "berry_number_per_vine", "berry_growth", "count/vine", "count/vine", FALSE, "vine basis"),
  list(b$hexose_g_per_berry, "hexose_per_berry", "sugar", "g/berry", "g/berry", TRUE, "berry basis"),
  list(b$hexose_g_per_vine, "hexose_per_vine", "sugar", "g/vine", "g/vine", TRUE, "vine basis"),
  list(b$berry_carbon_g_C_per_vine, "berry_carbon", "berry_growth", "g C/vine", "g C/vine", TRUE, "vine basis")
)) add_variable(bm, spec[[1]], spec[[2]], spec[[3]], "contextual_trait", spec[[4]], spec[[5]],
                source_id = "src_bobeica_original_workbook", method = if (spec[[6]]) "source_workbook_calculation" else "source_workbook_table",
                quality = "not_applicable", provenance = "A", measured = !spec[[6]], derived = spec[[6]],
                benjamin_declared = bd, benjamin_included = bi, basis = spec[[7]],
                conversion = if (spec[[6]]) "formula or aggregation present in source workbook" else "none")

# Etchebarne et al. 2010 Grenache experiment (2007 observations).
e <- read.csv(file.path(converted_dir, "etchebarne_clean.csv"), check.names = FALSE,
              stringsAsFactors = FALSE)
e_event <- sprintf("ET10_%s_DAF%s_R%s", e$treatment_id, e$days_after_flowering, e$replicate)
em <- make_meta(e, "etchebarne_2010_grenache", e_event, daf = num(e$days_after_flowering),
                stage = paste0("day ", e$days_after_flowering, " after anthesis"),
                treatment_group = "irrigation x leaf number")
ed <- e$benjamin_declared_subset; ei <- e$benjamin_final_script_included
add_variable(em, e$T, "air_temperature", "environment", "final_model_driver", "degree_C", "degree_C",
             source_id = "src_etchebarne_benjamin_csv", method = "historical_analysis_table", quality = "not_assessed",
             provenance = "C", measured = FALSE, benjamin_declared = ed, benjamin_included = ei,
             basis = "daily climate value joined to sampling date")
add_variable(em, e[[17]], "berry_pH", "model_direct_input", "intermediate_model_input_and_calibration_target",
             "dimensionless", "dimensionless", source_id = "src_etchebarne_benjamin_csv", method = "historical_analysis_table",
             quality = "not_applicable", provenance = "C", benjamin_declared = ed, benjamin_included = ei)
add_variable(em, e[[20]], "malate_concentration", "organic_acid", "calibration_target", "g/L", "mol/L",
             function(v) v / M_MALIC, source_id = "src_etchebarne_benjamin_csv", method = "historical_analysis_table",
             quality = "not_applicable", provenance = "C", benjamin_declared = ed, benjamin_included = ei,
             conversion = "g/L divided by 134.0874 g/mol")
add_variable(em, e[[21]], "tartrate_concentration", "organic_acid", "calibration_target", "g/L", "mol/L",
             function(v) v / M_TARTARIC, source_id = "src_etchebarne_benjamin_csv", method = "historical_analysis_table",
             quality = "not_applicable", provenance = "C", benjamin_declared = ed, benjamin_included = ei,
             conversion = "g/L divided by 150.087 g/mol")
add_variable(em, e[[27]], "potassium_concentration", "mineral", "final_model_driver", "mg/L", "mol/L",
             function(v) v / 1000 / M_K, source_id = "src_etchebarne_benjamin_csv", method = "historical_analysis_table",
             quality = "not_applicable", provenance = "C", benjamin_declared = ed, benjamin_included = ei,
             conversion = "mg/L divided by 1000 and 39.0983 g/mol")
e_specs <- list(
  list(6, "cluster_length", "berry_growth", "cm", "cm", "cluster basis"),
  list(7, "cluster_fresh_mass", "berry_growth", "g/cluster", "g/cluster", "cluster basis"),
  list(8, "rachis_fresh_mass", "berry_growth", "g/cluster", "g/cluster", "cluster basis"),
  list(9, "berry_mass_per_cluster", "berry_growth", "g/cluster", "g/cluster", "cluster basis"),
  list(10, "berry_number_per_cluster", "berry_growth", "count/cluster", "count/cluster", "cluster basis"),
  list(11, "berry_volume", "berry_growth", "mL/berry", "mL/berry", "mean berry volume"),
  list(12, "berry_fresh_mass", "berry_growth", "g/berry", "g/berry", "fresh mass per berry"),
  list(13, "berry_dry_mass", "berry_growth", "g/berry", "g/berry", "dry mass per berry"),
  list(14, "berry_water_volume", "water_status", "mL/berry", "mL/berry", "berry basis"),
  list(15, "berry_water_fraction", "water_status", "% FW", "% FW", "berry fresh-mass basis"),
  list(16, "berry_dry_matter_fraction", "berry_growth", "% FW", "% FW", "berry fresh-mass basis"),
  list(18, "titratable_acidity", "organic_acid", "g/L", "g/L", "juice; acid-equivalent basis unresolved"),
  list(19, "titratable_acidity_per_berry", "organic_acid", "mg/berry", "mg/berry", "berry basis"),
  list(22, "brix", "sugar", "degree_Brix", "degree_Brix", "juice soluble solids"),
  list(23, "total_soluble_sugar", "sugar", "g/L", "g/L", "juice"),
  list(24, "total_soluble_sugar_per_berry", "sugar", "mg/berry", "mg/berry", "berry basis"),
  list(25, "hexose", "sugar", "g/L", "g/L", "glucose plus fructose in juice"),
  list(26, "hexose_per_berry", "sugar", "mg/berry", "mg/berry", "berry basis"),
  list(28, "calcium_concentration", "mineral", "mg/L", "mg/L", "juice"),
  list(29, "magnesium_concentration", "mineral", "mg/L", "mg/L", "juice"),
  list(30, "sodium_concentration", "mineral", "mg/L", "mg/L", "juice")
)
for (spec in e_specs) add_variable(em, e[[spec[[1]]]], spec[[2]], spec[[3]], "contextual_trait",
                                   spec[[4]], spec[[5]], source_id = "src_etchebarne_original_2007",
                                   method = "source_workbook_table", quality = "not_applicable", provenance = "A",
                                   benjamin_declared = ed, benjamin_included = ei, basis = spec[[6]])

observations$value <- as.numeric(observations$value)
observations$value_original <- as.numeric(observations$value_original)
kl_rows <- observations$study_id == "kliewer_lider_1970"
observations$source_page[kl_rows] <- "767 (journal page)"
observations$source_figure[kl_rows & observations$cultivar == "Cardinal"] <- "Figure 2"
observations$source_figure[kl_rows & observations$cultivar == "Pinot Noir"] <- "Figure 3"
observations$notes[kl_rows] <- paste0(observations$notes[kl_rows],
  ifelse(observations$notes[kl_rows] == "", "", " "),
  "Workbook sheet/row cultivar annotations are swapped; cultivar was resolved against figure values and source tables.")
observations <- observations[order(observations$study_id, observations$cultivar,
                                   observations$treatment_id, observations$sampling_event_id,
                                   observations$variable), ]
rownames(observations) <- NULL
out <- file.path(converted_dir, "observations_standardized.csv")
write.csv(observations, out, row.names = FALSE, na = "")
cat(sprintf("Standardized %d non-missing observations -> %s\n", nrow(observations), out))
