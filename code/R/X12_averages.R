# X12_averages.R — seasonally adjust the NEW per-HH component aggregates for the DFA work.
#
# Copy of X12_script.R, repointed at THIS project. It de-seasons the newly-imported
# Financial-Accounts component series and ADDS them to the existing
# averages_deseasoned.csv, leaving the baseline columns (already de-seasoned and
# gap-filled there) untouched.
#
# WORKFLOW:
#   1. Run import_aggregates.do (run-now version) — its FRED import already includes the
#      new series, so it (re)writes averages_nominal_w_season.csv WITH these columns.
#   2. Run THIS script — averages_deseasoned.csv then gains the de-seasoned components.
#   3. Re-enable the 4 component anchors in import_aggregates.do and re-run it, so
#      inflation_corrected_correction_series.xlsx gets stocks/real_estate/business/pension_per_hh.
#
# Uses the same x12 engine as X12_script.R (needs the X-13ARIMA-SEATS binary installed).

setwd("/Users/lc/Dropbox/Distributional_Dynamics/2_Data_processing")
library(x12)

nom <- read.csv("aggregates/averages_nominal_w_season.csv", stringsAsFactors = FALSE)
des <- read.csv("aggregates/averages_deseasoned.csv",        stringsAsFactors = FALSE)
des$X <- NULL  # drop the leading row-index column read back in (re-added on write)

# New Financial-Accounts component series (header names as written by import_aggregates.do).
new_cols <- c("HNOCEA", "HNOMFSA", "HNOREMV", "BOGZ1LM152090205Q", "HNOPFAQ027S")

# Seasonally adjust one series: adjust only the observed (non-NA) span; keep original on failure.
deseason_series <- function(x, daten) {
  x  <- suppressWarnings(as.numeric(x))
  nz <- which(!is.na(x))
  if (length(nz) < 16) return(x)                 # too short to seasonally adjust
  a <- nz[1]; b <- nz[length(nz)]
  seg <- x[a:b]
  if (any(is.na(seg))) return(x)                 # internal gaps -> leave as-is
  # true calendar start of the observed span (daten like "1947q2") — without it,
  # ts() labels position 1 as Q1 and the calendar phase is wrong for any series
  # starting mid-year (harmless for the pure seasonal filter, wrong for calendar
  # regressors/diagnostics; the Julia X-13 wrapper passes the true start too)
  d0  <- tolower(as.character(daten[a]))
  yr0 <- as.integer(sub("q.*", "", d0))
  q0  <- as.integer(sub(".*q", "", d0))
  out <- tryCatch({
    obj <- new("x12Single", ts = ts(seg, frequency = 4, start = c(yr0, q0)))
    as.numeric(x12(obj)@x12Output@d11)
  }, error = function(e) { message("x12 failed for this series; keeping original"); seg })
  x[a:b] <- out
  x
}

for (col in new_cols) {
  if (!col %in% names(nom)) {
    warning(sprintf("Column '%s' not found in averages_nominal_w_season.csv — run import_aggregates.do first. Skipping.", col))
    next
  }
  adj <- deseason_series(nom[[col]], nom$daten)
  # align by quarterly date string (daten, e.g. "1989q3")
  map <- setNames(adj, as.character(nom$daten))
  des[[col]] <- as.numeric(map[as.character(des$daten)])
  message(sprintf("added de-seasoned column: %s", col))
}

# write.csv adds the leading row-index column, matching the existing file format.
write.csv(des, "aggregates/averages_deseasoned.csv")
