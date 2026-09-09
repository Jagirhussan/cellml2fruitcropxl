#!/usr/bin/env Rscript

if (!requireNamespace("ggplot2", quietly = TRUE)) {
  stop("Package 'ggplot2' is required to generate QC plots.")
}

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[1]) else "scripts/05_qc_plots.R"
script_path <- gsub("~+~", " ", script_path, fixed = TRUE)
package_dir <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
curated_dir <- file.path(package_dir, "curated")
report_dir <- file.path(package_dir, "qc", "reports")
figure_dir <- file.path(package_dir, "qc", "figures")

obs <- read.csv(file.path(curated_dir, "observations_long.csv"), stringsAsFactors = FALSE)
acid <- read.csv(file.path(curated_dir, "acid_model_inputs.csv"), stringsAsFactors = FALSE)
treat <- read.csv(file.path(curated_dir, "treatments.csv"), stringsAsFactors = FALSE)
manifest <- read.csv(file.path(package_dir, "source_manifest.csv"), stringsAsFactors = FALSE)
climate <- read.csv(file.path(curated_dir, "climate_long.csv"), stringsAsFactors = FALSE)

messages <- character()
check_result <- function(name, ok, detail = "") {
  messages <<- c(messages, sprintf("%s\t%s\t%s", if (ok) "PASS" else "FAIL", name, detail))
  if (!ok) warning(sprintf("QC failed: %s — %s", name, detail), call. = FALSE)
}

dup_key <- paste(obs$study_id, obs$cultivar, obs$treatment_id, obs$replicate,
                 obs$sampling_event_id, obs$variable, sep = "|")
dup <- duplicated(dup_key) | duplicated(dup_key, fromLast = TRUE)
write.csv(obs[dup, ], file.path(report_dir, "duplicate_observations.csv"), row.names = FALSE, na = "")
check_result("no duplicate sampling-unit variable records", !any(dup),
             sprintf("%d duplicate rows", sum(dup)))

recognized_units <- c("degree_C", "dimensionless", "mol/L", "g/berry", "degree_Brix",
                      "g tartaric_acid_equivalent/L", "g/L", "g H2SO4 equivalent/L", "mg/L",
                      "mg/100 g FW", "count/vine", "g/vine", "g C/vine", "count/cluster",
                      "g/cluster", "mL/berry", "% FW", "mg/berry")
recognized_units <- c(recognized_units, "cm")
bad_units <- setdiff(unique(obs$unit), recognized_units)
check_result("all canonical observation units recognized", !length(bad_units),
             paste(bad_units, collapse = "; "))

pH <- obs$value[obs$variable == "berry_pH"]
check_result("pH plausible", all(pH >= 1.5 & pH <= 5.5),
             sprintf("range %.3f to %.3f", min(pH), max(pH)))
nonnegative_categories <- c("organic_acid", "mineral", "sugar", "berry_growth",
                            "secondary_metabolite")
bad_negative <- obs[obs$variable_category %in% nonnegative_categories & obs$value < 0, ]
check_result("concentrations and fruit traits non-negative", !nrow(bad_negative),
             sprintf("%d negative records", nrow(bad_negative)))

temp_both <- !is.na(acid$temperature_C) & !is.na(acid$temperature_K)
temp_error <- abs(acid$temperature_K[temp_both] - acid$temperature_C[temp_both] - 273.15)
check_result("temperature Kelvin conversion", all(temp_error < 1e-10),
             sprintf("maximum absolute error %.3g K", max(temp_error)))

treat_key <- paste(treat$study_id, treat$cultivar, treat$treatment_id, sep = "|")
obs_treat_key <- paste(obs$study_id, obs$cultivar, obs$treatment_id, sep = "|")
missing_treatments <- setdiff(unique(obs_treat_key), treat_key)
check_result("treatment identities present in metadata", !length(missing_treatments),
             paste(missing_treatments, collapse = "; "))

required_roles <- c(air_temperature = "final_model_driver",
                    potassium_concentration = "final_model_driver",
                    berry_pH = "intermediate_model_input_and_calibration_target",
                    malate_concentration = "calibration_target",
                    tartrate_concentration = "calibration_target")
role_ok <- vapply(names(required_roles), function(v) {
  z <- unique(obs$model_role[obs$variable == v])
  length(z) == 1L && identical(z, unname(required_roles[v]))
}, logical(1))
check_result("Benjamin model roles assigned", all(role_ok),
             paste(names(role_ok)[!role_ok], collapse = "; "))

missing_sources <- setdiff(unique(obs$source_id), manifest$source_id)
check_result("every observation source resolves in manifest", !length(missing_sources),
             paste(missing_sources, collapse = "; "))
sha256_file <- function(path) {
  out <- system2("sha256sum", shQuote(path), stdout = TRUE)
  sub(" .*", "", out[1])
}
original_hash <- vapply(manifest$local_original_path, sha256_file, character(1))
check_result("curated raw copies match historical originals", all(original_hash == manifest$checksum),
             sprintf("%d checksum mismatches", sum(original_hash != manifest$checksum)))

# Source order should never reverse the developmental axis within a treatment.
converted <- file.path(package_dir, "intermediate", "converted")
source_sequence_checks <- list(
  kliewer = list(read.csv(file.path(converted, "kliewer_clean.csv")), c("cultivar","treatment_id"), "week_after_veraison"),
  soyer = list(read.csv(file.path(converted, "soyer_clean.csv")), "treatment_id", "day_of_year"),
  bobeica = list(read.csv(file.path(converted, "bobeica_clean.csv")), "treatment_id", "DAF"),
  etchebarne = list(read.csv(file.path(converted, "etchebarne_clean.csv")), "treatment_id", "days_after_flowering")
)
monotonic_bad <- character()
for (nm in names(source_sequence_checks)) {
  x <- source_sequence_checks[[nm]][[1]]
  groups <- interaction(x[, source_sequence_checks[[nm]][[2]], drop = FALSE], drop = TRUE)
  axis <- x[[source_sequence_checks[[nm]][[3]]]]
  bad <- vapply(split(axis, groups), function(v) any(diff(v) < 0, na.rm = TRUE), logical(1))
  if (any(bad)) monotonic_bad <- c(monotonic_bad, paste(nm, names(bad)[bad], sep = ":"))
}
check_result("developmental time non-decreasing in source order", !length(monotonic_bad),
             paste(monotonic_bad, collapse = "; "))

counts <- aggregate(value ~ study_id + cultivar + treatment_id + variable + unit,
                    obs, length)
names(counts)[names(counts) == "value"] <- "n_observations"
counts <- counts[order(counts$study_id, counts$cultivar, counts$treatment_id, counts$variable), ]
write.csv(counts, file.path(report_dir, "observation_counts.csv"), row.names = FALSE, na = "")

core <- data.frame(
  variable = c("temperature", "pH", "malate", "tartrate", "potassium", "berry_FW", "berry_DW", "sugar", "brix"),
  column = c("temperature_C", "berry_pH", "malate_mol_L", "tartrate_mol_L", "potassium_mol_L",
             "berry_fresh_mass_g", "berry_dry_mass_g", "sugar_g_L", "brix"), stringsAsFactors = FALSE
)
groups <- unique(acid[, c("study_id", "cultivar", "treatment_id")])
missingness <- do.call(rbind, lapply(seq_len(nrow(groups)), function(i) {
  z <- acid[acid$study_id == groups$study_id[i] & acid$cultivar == groups$cultivar[i] &
              acid$treatment_id == groups$treatment_id[i], ]
  group_row <- groups[i, , drop = FALSE]
  rownames(group_row) <- NULL
  data.frame(group_row, variable = unname(core$variable), n_sampling_units = nrow(z),
             n_available = vapply(core$column, function(v) sum(!is.na(z[[v]])), integer(1)),
             n_missing = vapply(core$column, function(v) sum(is.na(z[[v]])), integer(1)),
             stringsAsFactors = FALSE)
}))
write.csv(missingness, file.path(report_dir, "missingness_by_study_treatment_variable.csv"),
          row.names = FALSE, na = "")

core_counts <- missingness[missingness$variable %in%
  c("temperature", "pH", "malate", "tartrate", "potassium", "berry_FW", "berry_DW", "sugar", "brix"), ]
write.csv(core_counts, file.path(report_dir, "core_observation_counts.csv"),
          row.names = FALSE, na = "")

selection_audit <- do.call(rbind, lapply(split(acid, list(acid$study_id, acid$cultivar,
                                                         acid$treatment_id), drop = TRUE), function(z) {
  data.frame(study_id = z$study_id[1], cultivar = z$cultivar[1], treatment_id = z$treatment_id[1],
             n_sampling_units = nrow(z),
             n_benjamin_declared_subset = sum(z$benjamin_declared_subset),
             n_benjamin_final_script_included = sum(z$benjamin_final_script_included),
             n_complete_final_driver_target_rows = sum(stats::complete.cases(
               z[, c("temperature_C", "berry_pH", "malate_mol_L", "tartrate_mol_L", "potassium_mol_L")])),
             stringsAsFactors = FALSE)
}))
selection_audit$evidence_note <- ifelse(selection_audit$study_id == "etchebarne_2010_grenache",
  "Declared subset follows Benjamin report text (four of six) plus treatment definitions; actual inclusion exactly matches Grenache7.2 sampling keys.",
  "Declared use and final-script inclusion reconstructed from Benjamin report and final R script.")
write.csv(selection_audit, file.path(report_dir, "benjamin_selection_audit.csv"),
          row.names = FALSE, na = "")

availability <- aggregate(value ~ study_id + cultivar + variable, obs, length)
names(availability)[4] <- "n_observations"
write.csv(availability, file.path(report_dir, "variable_availability_by_study.csv"),
          row.names = FALSE, na = "")

climate_groups <- split(climate, list(climate$study_id, climate$variable), drop = TRUE)
climate_missingness <- do.call(rbind, lapply(climate_groups, function(z) data.frame(
  study_id = z$study_id[1], variable = z$variable[1], unit = z$unit[1],
  n_time_records = nrow(z), n_available = sum(!is.na(z$value)),
  n_missing = sum(is.na(z$value)), temporal_resolution = z$temporal_resolution[1],
  stringsAsFactors = FALSE)))
write.csv(climate_missingness, file.path(report_dir, "climate_missingness.csv"),
          row.names = FALSE, na = "")

plot_specs <- data.frame(
  variable = c("malate_concentration", "tartrate_concentration", "berry_pH",
               "potassium_concentration", "brix", "berry_fresh_mass"),
  label = c("Malate", "Tartrate", "pH", "Potassium", "Brix / sugar", "Berry fresh mass"),
  file = c("malate", "tartrate", "pH", "potassium", "sugar", "berry_FW"),
  stringsAsFactors = FALSE
)
studies <- unique(obs$study_id)
for (study in studies) {
  for (j in seq_len(nrow(plot_specs))) {
    z <- obs[obs$study_id == study & obs$variable == plot_specs$variable[j], ]
    file_name <- file.path(figure_dir, paste0(study, "_", plot_specs$file[j], ".png"))
    if (!nrow(z)) {
      grDevices::png(file_name, width = 1200, height = 800, res = 130)
      graphics::plot.new()
      graphics::text(0.5, 0.55, paste(plot_specs$label[j], "not available"), cex = 1.5)
      graphics::text(0.5, 0.45, study, cex = 1.1)
      grDevices::dev.off()
      next
    }
    z$x <- if (study == "kliewer_lider_1970") suppressWarnings(as.numeric(
             sub("^week ([0-9.]+) after veraison$", "\\1", z$development_stage))) else
           if (study %in% c("bobeica_2015_sangiovese", "etchebarne_2010_grenache")) z$days_after_flowering else
           as.integer(format(as.Date(z$calendar_date), "%j"))
    x_label <- if (study == "kliewer_lider_1970") "Weeks after veraison" else
               if (study %in% c("bobeica_2015_sangiovese", "etchebarne_2010_grenache")) "Days after flowering/anthesis" else
               "Day of year"
    p <- ggplot2::ggplot(z, ggplot2::aes(x = x, y = value, colour = treatment_id,
                                         group = treatment_id)) +
      ggplot2::stat_summary(fun = mean, geom = "line", linewidth = 0.7) +
      ggplot2::geom_point(alpha = 0.65, size = 1.4) +
      ggplot2::facet_wrap(~cultivar, scales = "free_y") +
      ggplot2::labs(title = paste(plot_specs$label[j], "QC —", study), x = x_label,
                    y = paste0(plot_specs$label[j], " [", unique(z$unit)[1], "]"), colour = "Treatment") +
      ggplot2::theme_bw(base_size = 11) +
      ggplot2::theme(legend.position = "bottom")
    ggplot2::ggsave(file_name, p, width = 9, height = 6, dpi = 130)
  }
}

writeLines(c(
  "Acid-model dataset quality-control summary",
  sprintf("Generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")),
  sprintf("Observation rows: %d", nrow(obs)),
  sprintf("Sampling units: %d", nrow(acid)),
  "",
  messages,
  "",
  "Interpretive cautions:",
  "- Kliewer potassium is structurally absent; its prescribed temperature regime is not hourly weather.",
  "- Bobeica DAF 105 has no potassium and is outside Benjamin's final coupled-model selection.",
  "- Etchebarne's declared A1/A2/B1/B2 subset and the 164 rows read by the final script are not identical.",
  "- Plausibility checks detect transcription/unit problems; they do not validate biological mechanisms."
), file.path(report_dir, "qc_summary.txt"))

if (any(grepl("^FAIL", messages))) quit(status = 1L)
cat(sprintf("QC passed: %d checks; %d figures written.\n", length(messages), length(studies) * nrow(plot_specs)))
