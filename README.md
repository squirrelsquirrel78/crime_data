This is a long-term project to collect and clean crime data (primarily FBI crime data) and make it accessible to the public. The code here is mostly to read in the data from the FBI raw files, clean it slightly, and combine years together for a single file.

## Repository Structure

| File | Description |
|------|-------------|
| `R/arrests.R` | Reads and cleans FBI Arrest Statistics (ASR) – age, sex, and **race of arrestee** by offense |
| `R/offenses_known.R` | Reads and cleans Return A (Offenses Known) – offense counts with no race breakdown |
| `R/SHR.R` | Reads and cleans Supplemental Homicide Reports – victim/offender demographics for homicides |
| `R/nibrs.R` | Reads and cleans all NIBRS segments including the victim segment (**race of victim** by offense) |
| `R/supplement_return_a.R` | Reads and cleans Supplement to Return A (property stolen/recovered) |
| `setup_files/` | SPSS-style setup files (.sps) that define column positions and value labels for each FBI raw file |
| `R/make_sps/` | Scripts that generate the setup files |
| `R/utils/` | Shared utility functions used across all data sources |

## How the Data Pipeline Works

1. Raw FBI fixed-width ASCII files are read using `asciiSetupReader::read_ascii_setup()` together with a matching `.sps` setup file from `setup_files/`.
2. Each script cleans one data type (arrests, offenses known, NIBRS, etc.) and saves annual `.rds` files.
3. A combine step (`combine_arrest_yearly()`, `get_data_yearly()`, etc.) stacks the annual files into a single multi-year dataset.

## Example: Aggravated Assault by Victim Race Over Time

See **`R/aggravated_assault_by_race.R`** for a worked example of this analysis using the NIBRS Victim Segment.

Each row in the NIBRS victim segment is one victim. The `race_of_victim` field
records the victim's race; `ucr_offense_code_1` through `ucr_offense_code_10`
record the associated offenses (value `"assault offenses - aggravated assault"`
for aggravated assault, NIBRS code 13A).

```r
# After running nibrs.R to produce cleaned victim segment files:
victim_data <- readRDS("...nibrs_victim_segment_2023.rds")

offense_cols <- grep("^ucr_offense_code_", names(victim_data), value = TRUE)
is_agg_assault <- rowSums(
  sapply(offense_cols, function(col)
    victim_data[[col]] %in% "assault offenses - aggravated assault")
) > 0

agg_assault_victims_by_race <-
  victim_data[is_agg_assault, ] %>%
  dplyr::group_by(year, race_of_victim) %>%
  dplyr::summarize(victims = dplyr::n(), .groups = "drop")
``` 