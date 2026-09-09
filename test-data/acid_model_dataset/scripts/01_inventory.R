#!/usr/bin/env Rscript

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
script_path <- if (length(script_arg)) sub("^--file=", "", script_arg[1]) else "scripts/01_inventory.R"
script_path <- gsub("~+~", " ", script_path, fixed = TRUE)
package_dir <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
archive_dir <- normalizePath(file.path(package_dir, ".."), mustWork = TRUE)

files <- list.files(archive_dir, recursive = TRUE, full.names = TRUE,
                    all.files = TRUE, include.dirs = FALSE, no.. = TRUE)
files <- files[!startsWith(normalizePath(files, mustWork = FALSE), paste0(package_dir, "/"))]

sha256_file <- function(path) {
  out <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = TRUE)
  if (!length(out)) return(NA_character_)
  sub(" .*", "", out[1])
}

info <- file.info(files)
relative_path <- substring(files, nchar(archive_dir) + 2L)
lower_path <- tolower(relative_path)
study_hint <- ifelse(grepl("kliewer|kliwer|cardinal|pinot", lower_path), "kliewer",
              ifelse(grepl("soyer|cabernet sauvignon|citpn90|m901|m902|matmoy90|data-1990", lower_path), "soyer",
              ifelse(grepl("bobeica|sangiovese|italy", lower_path), "bobeica",
              ifelse(grepl("etche|grenache|data of flor|météo jour 06-07", lower_path), "etchebarne", "other"))))

inventory <- data.frame(
  relative_path = relative_path,
  file_name = basename(files),
  extension = tolower(tools::file_ext(files)),
  size_bytes = info$size,
  modified_time = format(info$mtime, "%Y-%m-%dT%H:%M:%S%z"),
  study_hint = study_hint,
  sha256 = vapply(files, sha256_file, character(1)),
  stringsAsFactors = FALSE
)
inventory$duplicate_count <- ave(inventory$sha256, inventory$sha256,
                                 FUN = function(x) length(x))
inventory <- inventory[order(inventory$relative_path), ]

out <- file.path(package_dir, "qc", "reports", "historical_inventory.csv")
write.csv(inventory, out, row.names = FALSE, na = "")
cat(sprintf("Inventoried %d historical files (%d checksum-duplicate members).\n",
            nrow(inventory), sum(inventory$duplicate_count > 1L)))
cat(sprintf("Wrote %s\n", out))
