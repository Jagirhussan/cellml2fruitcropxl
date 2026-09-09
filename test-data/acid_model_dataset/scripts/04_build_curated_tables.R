#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[1]) else "scripts/04_build_curated_tables.R"
script_path <- gsub("~+~", " ", script_path, fixed = TRUE)
package_dir <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
archive_dir <- normalizePath(file.path(package_dir, ".."), mustWork = TRUE)
converted_dir <- file.path(package_dir, "intermediate", "converted")
curated_dir <- file.path(package_dir, "curated")

obs <- read.csv(file.path(converted_dir, "observations_standardized.csv"),
                check.names = FALSE, stringsAsFactors = FALSE)
write.csv(obs, file.path(curated_dir, "observations_long.csv"), row.names = FALSE, na = "")

first_or_na <- function(x) {
  x <- x[!is.na(x) & as.character(x) != ""]
  if (length(x)) x[1] else NA
}
lookup <- function(variable, field = "value") {
  z <- obs[obs$variable == variable, c("sampling_event_id", field), drop = FALSE]
  names(z)[2] <- variable
  z[!duplicated(z$sampling_event_id), ]
}

# One row for every recovered experimental sampling unit, including units with
# missing core acid-model values. No interpolation is performed.
event_fields <- c("study_id", "cultivar", "treatment_id", "replicate",
                  "sampling_event_id", "calendar_date", "year",
                  "days_after_flowering", "days_after_veraison", "development_stage",
                  "benjamin_declared_subset", "benjamin_final_script_included")
events <- unique(obs[, event_fields])
core_map <- c(
  temperature_C = "air_temperature",
  berry_pH = "berry_pH",
  malate_mol_L = "malate_concentration",
  tartrate_mol_L = "tartrate_concentration",
  potassium_mol_L = "potassium_concentration",
  berry_fresh_mass_g = "berry_fresh_mass",
  berry_dry_mass_g = "berry_dry_mass",
  sugar_g_L = "total_soluble_sugar",
  brix = "brix"
)
acid <- events
acid$weeks_after_veraison <- ifelse(acid$study_id == "kliewer_lider_1970",
  suppressWarnings(as.numeric(sub("^week ([0-9.]+) after veraison$", "\\1", acid$development_stage))), NA_real_)
for (out_name in names(core_map)) {
  z <- lookup(core_map[[out_name]], "value")
  names(z)[2] <- out_name
  acid <- merge(acid, z, by = "sampling_event_id", all.x = TRUE, sort = FALSE)
}
acid$temperature_K <- ifelse(is.na(acid$temperature_C), NA, acid$temperature_C + 273.15)

source_map <- c(temperature_source = "air_temperature", pH_source = "berry_pH",
                malate_source = "malate_concentration", tartrate_source = "tartrate_concentration",
                potassium_source = "potassium_concentration")
for (out_name in names(source_map)) {
  z <- lookup(source_map[[out_name]], "source_id")
  names(z)[2] <- out_name
  acid <- merge(acid, z, by = "sampling_event_id", all.x = TRUE, sort = FALSE)
}
measured_map <- c(temperature_measured = "air_temperature", pH_measured = "berry_pH",
                  malate_measured = "malate_concentration", tartrate_measured = "tartrate_concentration",
                  potassium_measured = "potassium_concentration")
for (out_name in names(measured_map)) {
  z <- lookup(measured_map[[out_name]], "is_measured")
  names(z)[2] <- out_name
  acid <- merge(acid, z, by = "sampling_event_id", all.x = TRUE, sort = FALSE)
}
for (nm in names(measured_map)) acid[[nm]] <- ifelse(is.na(acid[[nm]]), FALSE, acid[[nm]])

# Values calculated with Benjamin's rounded molar-mass denominators are retained
# separately for strict historical reproducibility, never as canonical values.
acid$malate_mol_L_benjamin2018 <- NA_real_
acid$tartrate_mol_L_benjamin2018 <- NA_real_
acid$potassium_mol_L_benjamin2018 <- NA_real_
k_hist <- read.csv(file.path(converted_dir, "kliewer_clean.csv"), check.names = FALSE)
s_hist <- read.csv(file.path(converted_dir, "soyer_clean.csv"), check.names = FALSE)
b_hist <- read.csv(file.path(converted_dir, "bobeica_clean.csv"), check.names = FALSE)
e_hist <- read.csv(file.path(converted_dir, "etchebarne_clean.csv"), check.names = FALSE)
historical <- rbind(
  data.frame(sampling_event_id = sprintf("KL70_%s_%s_WAV%s", gsub(" ", "_", k_hist$cultivar),
                                         k_hist$treatment_id, k_hist$week_after_veraison),
             malate = k_hist$Malate, tartrate = k_hist$Tartrate, potassium = NA_real_, potassium_unit = NA_character_),
  data.frame(sampling_event_id = sprintf("SO93_%s_DOY%s_R%s", s_hist$treatment_id, s_hist$day_of_year, s_hist$replicate),
             malate = s_hist$Malate, tartrate = s_hist$Tartrate, potassium = s_hist$K., potassium_unit = "g/L"),
  data.frame(sampling_event_id = sprintf("BO15_%s_DAF%s_R%s", b_hist$treatment_id, b_hist$DAF, b_hist$replicate),
             malate = b_hist$Malate, tartrate = b_hist$Tartrate, potassium = b_hist$K., potassium_unit = "mg/L"),
  data.frame(sampling_event_id = sprintf("ET10_%s_DAF%s_R%s", e_hist$treatment_id,
                                         e_hist$days_after_flowering, e_hist$replicate),
             malate = e_hist[[20]], tartrate = e_hist[[21]], potassium = e_hist[[27]], potassium_unit = "mg/L")
)
idx_hist <- match(acid$sampling_event_id, historical$sampling_event_id)
stopifnot(!any(is.na(idx_hist)), !anyDuplicated(historical$sampling_event_id))
acid$malate_value_benjamin_source <- historical$malate[idx_hist]
acid$malate_unit_benjamin_source <- "g/L"
acid$tartrate_value_benjamin_source <- historical$tartrate[idx_hist]
acid$tartrate_unit_benjamin_source <- "g/L"
acid$potassium_value_benjamin_source <- historical$potassium[idx_hist]
acid$potassium_unit_benjamin_source <- historical$potassium_unit[idx_hist]
acid$malate_mol_L_benjamin2018 <- acid$malate_value_benjamin_source / 134
acid$tartrate_mol_L_benjamin2018 <- acid$tartrate_value_benjamin_source / 150
historical_k_g_L <- ifelse(acid$potassium_unit_benjamin_source == "mg/L",
                            acid$potassium_value_benjamin_source / 1000,
                            acid$potassium_value_benjamin_source)
acid$potassium_mol_L_benjamin2018 <- historical_k_g_L / 39
acid <- acid[, c(
  "study_id", "cultivar", "treatment_id", "replicate", "sampling_event_id",
  "calendar_date", "year", "days_after_flowering", "days_after_veraison", "weeks_after_veraison", "development_stage",
  "temperature_C", "temperature_K", "berry_pH", "malate_mol_L", "tartrate_mol_L",
  "potassium_mol_L", "berry_fresh_mass_g", "berry_dry_mass_g", "sugar_g_L", "brix",
  "temperature_source", "pH_source", "malate_source", "tartrate_source", "potassium_source",
  "temperature_measured", "pH_measured", "malate_measured", "tartrate_measured",
  "potassium_measured", "benjamin_declared_subset", "benjamin_final_script_included",
  "malate_value_benjamin_source", "malate_unit_benjamin_source",
  "tartrate_value_benjamin_source", "tartrate_unit_benjamin_source",
  "potassium_value_benjamin_source", "potassium_unit_benjamin_source",
  "malate_mol_L_benjamin2018", "tartrate_mol_L_benjamin2018",
  "potassium_mol_L_benjamin2018"
)]
acid <- acid[order(acid$study_id, acid$cultivar, acid$treatment_id,
                   acid$days_after_flowering, acid$days_after_veraison,
                   acid$calendar_date, acid$replicate), ]
write.csv(acid, file.path(curated_dir, "acid_model_inputs.csv"), row.names = FALSE, na = "")

treatments <- data.frame(
  study_id = c(rep("kliewer_lider_1970", 8), rep("soyer_molot_1993", 3),
               rep("bobeica_2015_sangiovese", 2), rep("etchebarne_2010_grenache", 9)),
  treatment_id = c(rep(c("HL_T20", "HL_T30", "LL_T20", "LL_T30"), 2),
                   "K0", "K60", "K120", "3L", "12L",
                   "A1", "A2", "B1", "B2", "CI", "CNI",
                   "POOLED_A1_A2", "POOLED_B1_B2", "POOLED_A1_A2_B1_B2"),
  cultivar = c(rep("Cardinal", 4), rep("Pinot Noir", 4), rep("Cabernet Sauvignon", 3),
               rep("Sangiovese", 2), rep("Grenache", 9)),
  treatment_factor_1 = c(rep("day temperature", 8), rep("K2O fertilization", 3),
                         rep("leaves per shoot/cluster", 2), rep("irrigation", 9)),
  factor_1_value = c(rep(c(20,30,20,30), 2), 0,60,120,3,12,
                     1,1,0,0,1,0, rep(NA,3)),
  factor_1_unit = c(rep("degree_C", 8), rep("kg K2O/ha/year", 3), rep("leaves", 2),
                    rep("binary: 1 irrigated, 0 non-irrigated", 6), rep(NA,3)),
  treatment_factor_2 = c(rep("light regime", 8), rep(NA,5), rep("leaf number", 9)),
  factor_2_value = c(rep(c("high","high","low","low"), 2), rep(NA,5),
                     "10","5","10","5","18","18", rep(NA,3)),
  factor_2_unit = c(rep("categorical", 8), rep(NA,5), rep("leaves/shoot", 9)),
  leaf_number = c(rep(NA,11),3,12,10,5,10,5,18,18,rep(NA,3)),
  leaf_to_fruit_ratio = NA_character_,
  potassium_fertilization = c(rep(NA,8),0,60,120,rep(NA,11)),
  irrigation_level = c(rep(NA,13),"irrigated","irrigated","non-irrigated","non-irrigated",
                       "irrigated","non-irrigated",rep("pooled/unassignable",3)),
  water_status = c(rep(NA,13),"irrigated","irrigated","water-deficit","water-deficit",
                   "irrigated","water-deficit",rep("pooled/unassignable",3)),
  temperature_day = c(rep(c(20,30,20,30),2),rep(NA,14)),
  temperature_night = c(rep(15,8),rep(NA,14)),
  used_by_benjamin = c(rep(TRUE,13), rep(TRUE,4), FALSE,FALSE,FALSE,FALSE,FALSE),
  exclusion_reason = c(rep("",17),
                       "Declared four-treatment subset excludes 18-leaf control; nevertheless terminal CI rows occur in Grenache7.2 used by final plotting script.",
                       "Declared four-treatment subset excludes 18-leaf control; nevertheless terminal CNI rows occur in Grenache7.2 used by final plotting script.",
                       rep("Pooled early sample cannot be assigned to one treatment; retained because final script input includes it.",3)),
  notes = c(rep("Controlled regime; light intensity is retained because it is crossed with temperature.",8),
            rep("Cabernet Sauvignon LAB experiment.",3),
            rep("Source:sink manipulation; labels also occur as 3LC/12LC in narrative material.",2),
            "A1: irrigated, 10 leaves/shoot.", "A2: irrigated, 5 leaves/shoot.",
            "B1: non-irrigated, 10 leaves/shoot.", "B2: non-irrigated, 5 leaves/shoot.",
            "CI: irrigated, 18-leaf control.", "CNI: non-irrigated, 18-leaf control.",
            "Early pooled A1/A2 sample.", "Early pooled B1/B2 sample.",
            "Early pooled A1/A2/B1/B2 sample."),
  stringsAsFactors = FALSE
)
write.csv(treatments, file.path(curated_dir, "treatments.csv"), row.names = FALSE, na = "")

sampling <- unique(acid[, c("study_id", "cultivar", "treatment_id", "replicate",
                            "sampling_event_id", "calendar_date", "year",
                            "days_after_flowering", "days_after_veraison", "weeks_after_veraison", "development_stage")])
sampling$days_after_fruit_set <- NA_real_
sampling$days_after_treatment <- NA_real_
sampling$phenological_stage <- sampling$development_stage
sampling$original_x_axis_value <- ifelse(sampling$study_id == "kliewer_lider_1970", sampling$weeks_after_veraison,
                                  ifelse(sampling$study_id %in% c("bobeica_2015_sangiovese", "etchebarne_2010_grenache"),
                                         sampling$days_after_flowering,
                                         as.integer(format(as.Date(sampling$calendar_date), "%j"))))
sampling$original_x_axis_definition <- c(
  kliewer_lider_1970 = "weeks after veraison",
  soyer_molot_1993 = "day of year (1990)",
  bobeica_2015_sangiovese = "days after flowering",
  etchebarne_2010_grenache = "days after anthesis (JAA)"
)[sampling$study_id]
sampling$notes <- ifelse(sampling$study_id == "etchebarne_2010_grenache" &
                           grepl("POOLED", sampling$treatment_id),
                         "Early sample was pooled before treatment identity was separable.", "")
write.csv(sampling, file.path(curated_dir, "sampling_events.csv"), row.names = FALSE, na = "")

climate_rows <- list()
append_climate <- function(study_id, cultivar, treatment_id, datetime, date, year, doy,
                           daf, variable, value, unit, resolution, controlled,
                           measured, derived, source_id, notes) {
  climate_rows[[length(climate_rows) + 1L]] <<- data.frame(
    study_id, cultivar, treatment_id, datetime, calendar_date = date, year,
    day_of_year = doy, days_after_flowering = daf, variable,
    value = as.numeric(value), unit, temporal_resolution = resolution,
    controlled_environment = controlled, is_measured = measured, is_derived = derived,
    source_id, notes, stringsAsFactors = FALSE
  )
}

# Controlled regimes are metadata, not fabricated weather observations.
for (i in seq_len(nrow(treatments[treatments$study_id == "kliewer_lider_1970", ]))) {
  z <- treatments[treatments$study_id == "kliewer_lider_1970", ][i, ]
  append_climate(z$study_id, z$cultivar, z$treatment_id, NA, NA, 1970, NA, NA,
                 "day_temperature_regime", z$temperature_day, "degree_C", "prescribed regime",
                 TRUE, FALSE, FALSE, "src_kliewer_1970_publication",
                 "Set-point; not an observed hourly series.")
  append_climate(z$study_id, z$cultivar, z$treatment_id, NA, NA, 1970, NA, NA,
                 "night_temperature_regime", z$temperature_night, "degree_C", "prescribed regime",
                 TRUE, FALSE, FALSE, "src_kliewer_1970_publication",
                 "Set-point; not an observed hourly series.")
}
s_climate <- unique(s_hist[, c("calendar_date", "year", "day_of_year", "T")])
append_climate("soyer_molot_1993", "Cabernet Sauvignon", NA, NA,
               s_climate$calendar_date, s_climate$year, s_climate$day_of_year, NA,
               "air_temperature_sampling_date_join", s_climate$T, "degree_C",
               "sampling-date join", FALSE, FALSE, TRUE, "src_soyer_benjamin_csv",
               "Historical value associated with sampling date; station, aggregation window, and measurement provenance unresolved.")
bc <- read.csv(file.path(converted_dir, "bobeica_climate_clean.csv"), check.names = FALSE)
for (spec in list(c("par_direct_umol_m2_s","radiation_direct","umol/m2/s"),
                  c("par_diffuse_umol_m2_s","radiation_diffuse","umol/m2/s"),
                  c("vpd_kPa","vapour_pressure_deficit","kPa"),
                  c("air_temperature_C","air_temperature","degree_C"))) {
  append_climate("bobeica_2015_sangiovese", "Sangiovese", NA, NA, bc$calendar_date,
                 bc$year, bc$day_of_year, bc$day_of_year - 151, spec[2], bc[[spec[1]]], spec[3],
                 "daily", FALSE, TRUE, FALSE, "src_bobeica_climate", "Actual daily climate file.")
}
ec <- read.csv(file.path(converted_dir, "etchebarne_climate_clean.csv"), check.names = FALSE)
ec <- ec[ec$year == 2007, ]
for (spec in list(c("ETP","reference_evapotranspiration","mm/day"), c("RG","global_radiation","J/cm2/day"),
                  c("RR","rainfall","mm/day"), c("TM","air_temperature_mean","degree_C"),
                  c("TN","air_temperature_min","degree_C"), c("TX","air_temperature_max","degree_C"),
                  c("UM","relative_humidity_mean","percent"), c("UN","relative_humidity_min","percent"),
                  c("UX","relative_humidity_max","percent"), c("V","wind_speed_mean","m/s"),
                  c("VX","wind_speed_max","m/s"))) {
  append_climate("etchebarne_2010_grenache", "Grenache", NA, NA, ec$calendar_date, ec$year,
                 ec$day_of_year, ec$day_of_year - 148, spec[2], ec[[spec[1]]], spec[3], "daily",
                 FALSE, TRUE, FALSE, "src_etchebarne_climate",
                 "INRA daily station series; units follow workbook metadata and require confirmation for RG/V.")
}
climate <- do.call(rbind, climate_rows)
write.csv(climate, file.path(curated_dir, "climate_long.csv"), row.names = FALSE, na = "")

catalog <- data.frame(
  study_id = c("kliewer_lider_1970", "kliewer_lider_1970", "soyer_molot_1993",
               "bobeica_2015_sangiovese", "etchebarne_2010_grenache"),
  citation = c(rep("Kliewer & Lider (1970)",2), "Soyer & Molot (1993)",
               "Bobeica et al. (2015)", "Etchebarne et al. (2010)"),
  cultivar = c("Cardinal", "Pinot Noir", "Cabernet Sauvignon", "Sangiovese", "Grenache"),
  experiment_location = c("controlled environment; Davis, California", "controlled environment; Davis, California",
                          "LAB code in workbook; full site unresolved", "Italy; full site unresolved from workbook",
                          "INRA Pech Rouge, Gruissan, France"),
  experiment_year = c("not stated in recovered table", "not stated in recovered table", "1990", "2013", "2007"),
  growing_environment = c("controlled environment", "controlled environment", "field", "field", "field"),
  treatment_type = c("day temperature x light", "day temperature x light", "potassium fertilization",
                     "source:sink (leaf number)", "irrigation x source:sink (leaf number)"),
  number_of_treatments = c(4,4,3,2,6),
  treatment_names = c(rep("HL_T20; HL_T30; LL_T20; LL_T30",2), "K0; K60; K120", "3L; 12L",
                      "A1; A2; B1; B2; CI; CNI (plus pooled early sampling identities)"),
  sampling_start = c("1 week after veraison", "1 week after veraison", "1990-07-16", "33 days after flowering", "17 days after anthesis"),
  sampling_end = c("5 weeks after veraison", "5 weeks after veraison", "1990-10-08", "105 days after flowering", "121 days after anthesis"),
  number_of_sampling_events = c(5,5,13,14,12),
  developmental_time_definition = c("weeks after veraison", "weeks after veraison", "day of year", "days after flowering", "days after anthesis (JAA)"),
  climate_available = c("prescribed day/night regime only", "prescribed day/night regime only", "sampling-date joined temperature only", "actual daily temperature, VPD and PAR", "actual daily station weather"),
  potassium_available = c(FALSE,FALSE,TRUE,TRUE,TRUE), pH_available = TRUE,
  malate_available = TRUE, tartrate_available = TRUE, sugar_available = TRUE,
  berry_FW_available = TRUE, berry_DW_available = c(FALSE,FALSE,FALSE,FALSE,TRUE),
  other_traits_available = c("Brix; total acidity", "Brix; total acidity", "Brix; total acidity; Mg; Ca",
                             "hexose; total acidity; anthocyanin; berry/vine and carbon aggregates",
                             "volume; cluster traits; water; sugars; titratable acidity; Ca; Mg; Na"),
  used_by_benjamin = TRUE,
  role_in_original_model = c("intermediate malate/tartrate fits; excluded from final coupled model because K is absent",
                             "intermediate malate/tartrate fits; excluded from final coupled model because K is absent",
                             "intermediate and final coupled model", "intermediate and final coupled model",
                             "intermediate and final coupled model; declared subset and script rows conflict"),
  provenance_quality = c("D","D","A/C","A/C","A/C"),
  notes = c(rep("Benjamin calls this Kliewer et al. 1965; design, workbook, and surviving paper support Kliewer & Lider 1970.",2),
            "117 LAB Cabernet Sauvignon observations (3 treatments x 13 dates x 3 replicates).",
            "DAF 105 has no K and is excluded by Benjamin's final-model script.",
            "Four intended treatments are A1/A2/B1/B2. The final Grenache7.2 input also retains pooled early samples and terminal CI/CNI rows."),
  stringsAsFactors = FALSE
)
write.csv(catalog, file.path(package_dir, "dataset_catalog.csv"), row.names = FALSE, na = "")

# Build a checksum-backed source manifest for every copied source file.
raw_files <- list.files(file.path(package_dir, "raw"), recursive = TRUE, full.names = TRUE,
                        all.files = TRUE, include.dirs = FALSE)
sha256_file <- function(path) {
  out <- system2("sha256sum", shQuote(path), stdout = TRUE)
  sub(" .*", "", out[1])
}
sha <- vapply(raw_files, sha256_file, character(1))
inventory <- read.csv(file.path(package_dir, "qc", "reports", "historical_inventory.csv"),
                      stringsAsFactors = FALSE)
original_for <- function(hash) {
  p <- inventory$relative_path[inventory$sha256 == hash]
  p <- p[order(nchar(p), p)]
  if (length(p)) file.path(archive_dir, p[1]) else NA_character_
}
rel <- substring(raw_files, nchar(package_dir) + 2L)
base <- basename(raw_files)
study_id <- ifelse(grepl("^raw/kliewer", rel), "kliewer_lider_1970",
            ifelse(grepl("^raw/soyer", rel), "soyer_molot_1993",
            ifelse(grepl("^raw/bobeica", rel), "bobeica_2015_sangiovese",
            ifelse(grepl("^raw/etchebarne", rel), "etchebarne_2010_grenache", "benjamin_2018"))))
special_ids <- c(
  "Kliewer 29-01_Dai.csv"="src_kliewer_benjamin_csv", "data from literature.xlsx"="src_kliewer_digitization_workbook",
  "1970-Kliewer and Lider_Kliewer_JAmerSocHortSci.pdf"="src_kliewer_1970_publication",
  "1965_Kliwer_changes in the concentration of malate tartrates and free acid.pdf"="src_kliewer_1965_conflicting_publication",
  "Soyer.csv"="src_soyer_benjamin_csv", "copieDATA-1990.xlsx"="src_soyer_original_workbook",
  "Sangiovese.csv"="src_bobeica_benjamin_csv", "2013_Italy_developmental profile.xls"="src_bobeica_original_workbook",
  "2015_Bobeica_sugars and anthocyanins.pdf"="src_bobeica_publication", "2013_Italy_climate data.xlsx"="src_bobeica_climate",
  "Grenache 2007.csv"="src_etchebarne_benjamin_csv", "Grenache7.2.csv"="src_etchebarne_final_input_csv",
  "Données (2007) Thèse F.Etchebarne.xlsx"="src_etchebarne_original_2007",
  "Données (2006) Thèse F.Etchebarne.xlsx"="src_etchebarne_original_2006",
  "2008_Etchebarne.pdf"="src_etchebarne_thesis", "météo jour 06-07 INRA.xls"="src_etchebarne_climate",
  "2018_Rapport M2 BTT.pdf"="src_benjamin_report", "figurerapport and parameter estimation.R"="src_benjamin_final_script",
  "acid_model_workspace.RData"="src_benjamin_rdata", "acid_model_workspace.Rhistory"="src_benjamin_rhistory"
)
slug <- function(x) gsub("(^_|_$)", "", gsub("[^a-z0-9]+", "_", tolower(iconv(x, to="ASCII//TRANSLIT"))))
source_id <- unname(special_ids[base])
source_id[is.na(source_id)] <- paste0("src_", slug(dirname(rel[is.na(source_id)])), "_", slug(base[is.na(source_id)]))
role <- ifelse(grepl("[.]pdf$", base, ignore.case=TRUE), "publication",
        ifelse(grepl("climate|météo", base, ignore.case=TRUE), "original_data",
        ifelse(grepl("[.]R$|Rhistory$|RData$", base, ignore.case=TRUE), "analysis_script",
        ifelse(grepl("digitization_excluded", rel), "digitized_data",
        ifelse(grepl("[.]csv$", base, ignore.case=TRUE), "model_input", "original_data")))))
role[base == "2008_Etchebarne.pdf"] <- "publication"
role[base == "2015_Bobeica_sugars and anthocyanins.pdf"] <- "publication"
role[base == "acid_model_workspace.RData"] <- "derived_data"
citation <- c(kliewer_lider_1970="Kliewer & Lider (1970)", soyer_molot_1993="Soyer & Molot (1993)",
              bobeica_2015_sangiovese="Bobeica et al. (2015)", etchebarne_2010_grenache="Etchebarne et al. (2010)",
              benjamin_2018="Tiffon-Terrade (2018)")[study_id]
cultivar <- c(kliewer_lider_1970="Cardinal; Pinot Noir", soyer_molot_1993="Cabernet Sauvignon",
              bobeica_2015_sangiovese="Sangiovese", etchebarne_2010_grenache="Grenache",
              benjamin_2018="multiple")[study_id]
cultivar[grepl("digitization_excluded", rel)] <- "Cabernet Sauvignon (excluded branch)"
source_year <- c(kliewer_lider_1970=1970, soyer_molot_1993=1993,
                 bobeica_2015_sangiovese=2015, etchebarne_2010_grenache=2010,
                 benjamin_2018=2018)[study_id]
source_year[base == "1965_Kliwer_changes in the concentration of malate tartrates and free acid.pdf"] <- 1965
source_year[base == "2008_Etchebarne.pdf"] <- 2008
citation[base == "1965_Kliwer_changes in the concentration of malate tartrates and free acid.pdf"] <- "Kliewer (1965), citation-conflict source"
citation[base == "2008_Etchebarne.pdf"] <- "Etchebarne (2008) doctoral thesis"
notes <- rep("", length(raw_files))
notes[grepl("digitization_excluded", rel)] <- "Cabernet Sauvignon material from the Bobeica study; copied for provenance but excluded from the target Sangiovese dataset."
notes[base == "1965_Kliwer_changes in the concentration of malate tartrates and free acid.pdf"] <- "Conflicting thesis citation: this 1965 paper does not describe the recovered controlled Cardinal/Pinot Noir design."
notes[base == "1970-Kliewer and Lider_Kliewer_JAmerSocHortSci.pdf"] <- "Design-matched publication for the historical digitization."
notes[base == "Grenache7.2.csv"] <- "Actual 164-row Grenache table read by Benjamin's final plotting/model script; includes pooled and CI/CNI rows."
manifest <- data.frame(
  source_id, study_id, citation, year = source_year,
  cultivar, local_original_path = vapply(sha, original_for, character(1)),
  curated_copy_path = rel, file_type = tolower(tools::file_ext(raw_files)), role,
  extraction_method = ifelse(role == "digitized_data", "historical_digitization",
                      ifelse(role == "analysis_script", "historical_analysis", "copied_unchanged")),
  source_table = "", source_figure = "", source_page = "", notes, checksum = sha,
  provenance_quality = ifelse(role == "original_data", "A",
                       ifelse(role == "digitized_data", "D",
                       ifelse(role %in% c("model_input", "derived_data", "analysis_script"), "C", "F"))),
  stringsAsFactors = FALSE
)
manifest$source_page[manifest$source_id %in% c("src_kliewer_1970_publication",
                                               "src_kliewer_digitization_workbook",
                                               "src_kliewer_benjamin_csv")] <- "767 (journal page)"
manifest$source_figure[manifest$source_id %in% c("src_kliewer_1970_publication",
                                                 "src_kliewer_digitization_workbook",
                                                 "src_kliewer_benjamin_csv")] <- "Figures 2-3"
manifest$notes[manifest$source_id == "src_kliewer_1970_publication"] <- paste(
  "Compiled scan containing several related Kliewer articles; the design-matched source is",
  "Kliewer & Lider (1970), journal pages 766-769, located at PDF pages 14-17. Figures 2-3 are the digitized source.")
manifest <- manifest[order(manifest$study_id, manifest$curated_copy_path), ]
stopifnot(!anyDuplicated(manifest$source_id), all(file.exists(manifest$local_original_path)))
write.csv(manifest, file.path(package_dir, "source_manifest.csv"), row.names = FALSE, na = "")

cat(sprintf("Curated %d observations, %d sampling units, %d climate records, and %d source files.\n",
            nrow(obs), nrow(acid), nrow(climate), nrow(manifest)))
