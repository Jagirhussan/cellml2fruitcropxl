#!/usr/bin/env Rscript

if (!requireNamespace("readxl", quietly = TRUE)) {
  stop("Package 'readxl' is required. Install it before running this script.")
}

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[1]) else "scripts/02_import_and_clean.R"
script_path <- gsub("~+~", " ", script_path, fixed = TRUE)
package_dir <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
raw_dir <- file.path(package_dir, "raw")
converted_dir <- file.path(package_dir, "intermediate", "converted")

num <- function(x) suppressWarnings(as.numeric(as.character(x)))
write_clean <- function(x, name) {
  path <- file.path(converted_dir, name)
  write.csv(x, path, row.names = FALSE, na = "")
  cat(sprintf("%s: %d rows -> %s\n", name, nrow(x), path))
}

parse_french_date_2007 <- function(x) {
  z <- tolower(iconv(x, to = "ASCII//TRANSLIT"))
  z <- gsub("\\.", "", z)
  month <- ifelse(grepl("juin", z), 6L,
           ifelse(grepl("juillet", z), 7L,
           ifelse(grepl("ao", z), 8L,
           ifelse(grepl("sept", z), 9L, NA_integer_))))
  day <- suppressWarnings(as.integer(sub("^([0-9]+).*", "\\1", z)))
  as.Date(sprintf("2007-%02d-%02d", month, day))
}

# Kliewer & Lider 1970: Benjamin's historical PlotDigitizer-derived model table.
kl_path <- file.path(raw_dir, "kliewer_1965", "Kliewer 29-01_Dai.csv")
kl <- read.csv(kl_path, skip = 1, check.names = FALSE, stringsAsFactors = FALSE,
               fileEncoding = "latin1")
kl$cultivar <- ifelse(tolower(kl$cepage) == "cardinal", "Cardinal", "Pinot Noir")
kl$light_regime <- kl$traitement
kl$treatment_id <- paste0(kl$light_regime, "_T", num(kl$T))
kl$week_after_veraison <- num(kl$Mois)
kl$replicate <- NA_character_
kl$year <- 1970L
kl$calendar_date <- NA_character_
kl$benjamin_declared_subset <- TRUE
kl$benjamin_final_script_included <- FALSE

# Add total acidity from the historical digitization workbook without replacing
# the model-input values in the CSV. Workbook sheet labels are internally swapped.
kl_book <- file.path(raw_dir, "kliewer_1965", "data from literature.xlsx")
card <- suppressMessages(readxl::read_excel(kl_book, sheet = "Cardinal",
                                             col_names = FALSE, skip = 3))
names(card)[1:5] <- c("week_after_veraison", "total_acidity_g_100ml",
                      "variable", "light_regime", "day_temperature_C")
card <- card[card$variable == "TA", c("week_after_veraison", "total_acidity_g_100ml",
                                      "light_regime", "day_temperature_C")]
card$cultivar <- "Cardinal"

pn <- suppressMessages(readxl::read_excel(kl_book, sheet = "Pinot Noir",
                                           col_names = TRUE, skip = 3))
names(pn) <- make.names(names(pn), unique = TRUE)
pn_ta_name <- names(pn)[tolower(names(pn)) == "ta"][1]
pn <- data.frame(
  week_after_veraison = num(pn[[1]]),
  total_acidity_g_100ml = num(pn[[pn_ta_name]]),
  light_regime = as.character(pn$light),
  day_temperature_C = num(pn$Temp.day),
  cultivar = "Pinot Noir",
  stringsAsFactors = FALSE
)
kl_ta <- rbind(as.data.frame(card), pn)
kl <- merge(kl, kl_ta,
            by.x = c("cultivar", "light_regime", "T", "week_after_veraison"),
            by.y = c("cultivar", "light_regime", "day_temperature_C", "week_after_veraison"),
            all.x = TRUE, sort = FALSE)
stopifnot(nrow(kl) == 40L, sum(!is.na(kl$total_acidity_g_100ml)) == 40L)
write_clean(kl, "kliewer_clean.csv")

# Soyer & Molot 1993: restrict to the LAB Cabernet Sauvignon K0/K60/K120
# experiment used in Benjamin's final model, retaining biological replicates.
so_path <- file.path(raw_dir, "soyer_1993", "Soyer.csv")
so <- read.csv(so_path, skip = 1, check.names = FALSE, stringsAsFactors = FALSE,
               fileEncoding = "latin1")
so <- so[so$Cepage == "Cabernet Sauvignon" & so$Localisation == "LAB" &
           so$traitement %in% c("Temoin K0", "K60", "K120"), ]
so$treatment_id <- c("Temoin K0" = "K0", "K60" = "K60", "K120" = "K120")[so$traitement]
so$cultivar <- "Cabernet Sauvignon"
so$replicate <- as.character(so[[17]])
so$year <- 1990L
so$day_of_year <- num(so$Jour)
so$calendar_date <- as.character(as.Date("1990-01-01") + so$day_of_year - 1L)
so$benjamin_declared_subset <- TRUE
so$benjamin_final_script_included <- TRUE

# Original numerical workbook supplies titratable acidity, Ca, and Mg.
so_book <- file.path(raw_dir, "soyer_1993", "copieDATA-1990.xlsx")
sx <- suppressMessages(readxl::read_excel(so_book, sheet = "Feuil1",
                                           col_names = FALSE, skip = 3))
sx <- as.data.frame(sx, stringsAsFactors = FALSE)
names(sx) <- paste0("V", seq_len(ncol(sx)))
sx <- sx[sx$V3 == "LAB" & sx$V4 %in% c("K 0", "K  60", "K 120"), ]
sx$treatment_id <- c("K 0" = "K0", "K  60" = "K60", "K 120" = "K120")[sx$V4]
sx$replicate <- as.character(sx$V5)
sx$day_of_year <- num(sx$V2)
extra <- data.frame(
  day_of_year = sx$day_of_year,
  treatment_id = sx$treatment_id,
  replicate = sx$replicate,
  total_acidity_g_H2SO4_eq_L = num(sx$V11),
  malate_meq_L = num(sx$V17),
  tartrate_meq_L = num(sx$V18),
  potassium_g_L_source = num(sx$V20),
  magnesium_mg_L = num(sx$V23),
  calcium_mg_L = num(sx$V24),
  stringsAsFactors = FALSE
)
so <- merge(so, extra, by = c("day_of_year", "treatment_id", "replicate"),
            all.x = TRUE, sort = FALSE)
stopifnot(nrow(so) == 117L,
          all(table(so$treatment_id) == 39L),
          sum(!is.na(so$total_acidity_g_H2SO4_eq_L)) == 117L)
write_clean(so, "soyer_clean.csv")

# Bobeica et al. 2015 Sangiovese experiment. The cleaned CSV contains the
# numerical series used by Benjamin; the original workbook restores replicate
# identifiers and additional fruit-quality traits.
bo_path <- file.path(raw_dir, "bobeica_2015", "Sangiovese.csv")
bo <- read.csv(bo_path, skip = 1, check.names = FALSE, stringsAsFactors = FALSE,
               fileEncoding = "latin1")
bo_book <- file.path(raw_dir, "bobeica_2015", "2013_Italy_developmental profile.xls")
bx <- suppressMessages(readxl::read_excel(bo_book, col_names = TRUE, skip = 1))
names(bx) <- make.names(names(bx), unique = TRUE)
stopifnot(nrow(bo) == nrow(bx))
# Benjamin's CSV is sorted by treatment whereas the source workbook is sorted
# by sampling event. Match rows by treatment, DAF, and within-event replicate.
bo$replicate <- ave(seq_len(nrow(bo)), interaction(bo$traitement, bo$DAF),
                    FUN = seq_along)
bo_key <- paste(bo$traitement, num(bo$DAF), bo$replicate, sep = "|")
bx_key <- paste(bx$treat, num(bx$daf), num(bx$rep), sep = "|")
idx <- match(bo_key, bx_key)
stopifnot(!any(is.na(idx)), !anyDuplicated(bx_key))
bx <- bx[idx, ]
stopifnot(all(num(bo$DAF) == num(bx$daf)),
          all(as.character(bo$traitement) == as.character(bx$treat)))
bo$replicate <- as.character(bx$rep)
bo$treatment_id <- as.character(bo$traitement)
bo$cultivar <- "Sangiovese"
bo$day_of_year <- num(bo$Jour)
bo$calendar_date <- as.character(as.Date("2013-01-01") + bo$day_of_year - 1L)
bo$hexose_g_L <- num(bx$Hexose)
bo$total_acidity_g_L <- num(bx$total.acidity)
bo$total_anthocyanin_mg_100g_FW <- num(bx$total.anth)
bo$berry_number_per_vine <- num(bx$berry.vine)
bo$hexose_g_per_berry <- num(bx$hexose.berry)
bo$hexose_g_per_vine <- num(bx$hexose.vine)
bo$berry_carbon_g_C_per_vine <- num(bx$carbon.berry.vine)
bo$benjamin_declared_subset <- TRUE
bo$benjamin_final_script_included <- num(bo$DAF) != 105L
stopifnot(nrow(bo) == 76L, sum(bo$benjamin_final_script_included) == 72L)
write_clean(bo, "bobeica_clean.csv")

# Etchebarne et al. 2010 / 2007 Grenache data. Preserve pooled early samples and
# both 18-leaf controls instead of assigning them to the four intended treatments.
et_path <- file.path(raw_dir, "etchebarne_2010", "Grenache 2007.csv")
et <- read.csv(et_path, skip = 1, check.names = FALSE, stringsAsFactors = FALSE,
               fileEncoding = "latin1")
raw_treatment <- as.character(et$Traitements)
et$treatment_id <- c(
  "A1" = "A1", "A2" = "A2", "B1" = "B1", "B2" = "B2",
  "CI" = "CI", "CnonI" = "CNI",
  "A1 A2" = "POOLED_A1_A2", "B1 B2" = "POOLED_B1_B2",
  "A1 A2 B1 B2" = "POOLED_A1_A2_B1_B2"
)[raw_treatment]
stopifnot(!any(is.na(et$treatment_id)))
et$cultivar <- "Grenache"
et$replicate <- as.character(et$Repetition)
et$year <- 2007L
et$days_after_flowering <- num(et$jaa)
et$calendar_date <- as.character(parse_french_date_2007(et$Date))
et$benjamin_declared_subset <- et$treatment_id %in% c("A1", "A2", "B1", "B2")
et$benjamin_final_script_included <- !is.na(et[[20]]) & !is.na(et[[21]]) & !is.na(et[[27]])
stopifnot(nrow(et) == 184L, sum(et$benjamin_final_script_included) == 164L)
# Confirm that the inferred non-missingness rule reproduces the exact sampling
# keys in Grenache7.2.csv, the table read by Benjamin's final script.
et_final <- read.csv(file.path(raw_dir, "etchebarne_2010", "Grenache7.2.csv"), skip = 1,
                     check.names = FALSE, stringsAsFactors = FALSE, fileEncoding = "latin1")
key_all <- paste(et$jaa, raw_treatment, et$Repetition, sep = "|")
key_final <- paste(et_final$jaa, et_final$Traitements, et_final$Repetition, sep = "|")
stopifnot(nrow(et_final) == 164L,
          setequal(key_all[et$benjamin_final_script_included], key_final),
          !anyDuplicated(key_final))
write_clean(et, "etchebarne_clean.csv")

# Actual daily climate series for Sangiovese.
bc_path <- file.path(raw_dir, "bobeica_2015", "2013_Italy_climate data.xlsx")
bc <- suppressMessages(readxl::read_excel(bc_path, col_names = TRUE, skip = 1))
names(bc)[1:5] <- c("day_of_year", "par_direct_umol_m2_s", "par_diffuse_umol_m2_s",
                    "vpd_kPa", "air_temperature_C")
bc <- as.data.frame(bc[!is.na(num(bc$day_of_year)), 1:5])
bc$day_of_year <- num(bc$day_of_year)
bc$year <- 2013L
bc$calendar_date <- as.character(as.Date("2013-01-01") + bc$day_of_year - 1L)
write_clean(bc, "bobeica_climate_clean.csv")

# Actual daily INRA weather for the 2006-2007 Grenache experiment.
ec_path <- file.path(raw_dir, "etchebarne_2010", "météo jour 06-07 INRA.xls")
ec <- suppressMessages(readxl::read_excel(ec_path, col_names = TRUE, skip = 59))
ec <- as.data.frame(ec, stringsAsFactors = FALSE)
needed <- c("NUM_POSTE", "AN", "MOIS", "JOUR", "ETP", "RG", "RR", "TM", "TN", "TX",
            "UM", "UN", "UX", "V", "VX")
missing_needed <- setdiff(needed, names(ec))
if (length(missing_needed)) stop("Missing expected climate columns: ", paste(missing_needed, collapse = ", "))
ec <- ec[, needed]
ec$calendar_date <- as.character(as.Date(sprintf("%04d-%02d-%02d", num(ec$AN), num(ec$MOIS), num(ec$JOUR))))
ec$day_of_year <- as.integer(format(as.Date(ec$calendar_date), "%j"))
names(ec)[names(ec) == "AN"] <- "year"
write_clean(ec, "etchebarne_climate_clean.csv")
