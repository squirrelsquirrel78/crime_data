# Aggravated Assault by Victim Race Over Time
#
# This script analyzes FBI crime data on aggravated assault broken down by
# victim demographics (race) over time using the NIBRS Victim Segment.
#
# METHODOLOGY OVERVIEW
# ====================
# Data source: NIBRS VICTIM SEGMENT (National Incident-Based Reporting System)
#    - Source: nibrs.R / setup_files/nibrs_victim_segment.sps
#    - What it measures: Race of the VICTIM (true victim demographics)
#    - Available: 1991-present (agency coverage grew over time)
#    - Offense filter: ucr_offense_code_* == "assault offenses - aggravated assault"
#    - Race field: race_of_victim ("white", "black",
#                                  "american indian/alaskan native", "asian")
#
# HOW THIS REPOSITORY PROCESSES FBI DATA
# =======================================
# Raw FBI ASCII fixed-width files are read using SPSS-style setup files (.sps)
# via the asciiSetupReader package. The setup files in setup_files/ define the
# column positions and value labels. The cleaned, combined files are saved as
# .rds files to a local data storage path.
#
# Once the data has been cleaned (via nibrs.R), use the analysis function
# below on the resulting .rds files.


# ---- NIBRS Victim Segment (Victim Race by Offense) ----
#
# Each row in the NIBRS victim segment is one victim in one incident.
# A victim can be linked to up to 10 offense codes (ucr_offense_code_1 through
# ucr_offense_code_10), so we check all of them.

analyze_aggravated_assault_victims_by_race <- function(
    nibrs_victim_folder = "E:/ucr_data_storage/clean_data/nibrs/victim_segment/"
) {
  files <- list.files(nibrs_victim_folder, pattern = "\\.rds$", full.names = TRUE)

  results <- vector("list", length(files))
  for (i in seq_along(files)) {
    victim_data <- readRDS(files[i])

    # ucr_offense_code columns use the label "assault offenses - aggravated assault"
    # which corresponds to NIBRS offense code 13A.
    offense_cols <- grep("^ucr_offense_code_", names(victim_data), value = TRUE)
    is_agg_assault <- rowSums(
      sapply(
        offense_cols,
        function(col) victim_data[[col]] %in% "assault offenses - aggravated assault"
      )
    ) > 0

    agg_assault_victims <- victim_data[is_agg_assault, ]

    # Count victims by year and race
    results[[i]] <-
      agg_assault_victims %>%
      dplyr::group_by(year, race_of_victim) %>%
      dplyr::summarize(victims = dplyr::n(), .groups = "drop")

    message(files[i])
  }

  # Combine all years and sum in case a single rds covers multiple years
  combined <-
    dplyr::bind_rows(results) %>%
    dplyr::group_by(year, race_of_victim) %>%
    dplyr::summarize(victims = sum(victims), .groups = "drop") %>%
    dplyr::arrange(year, race_of_victim)

  return(combined)
}


# ---- RUN THE ANALYSIS ----

source("R/utils/global_utils.R")

# NIBRS-based victim analysis (victim race, 1991-present)
agg_assault_victims_by_race <- analyze_aggravated_assault_victims_by_race()
print(agg_assault_victims_by_race)

# Save results
saveRDS(
  agg_assault_victims_by_race,
  "E:/ucr_data_storage/clean_data/nibrs/aggravated_assault_victims_by_race.rds"
)
