# Harmonize data on public holidays

# Init ------------------------------------------------------------

cat(crayon::blue(crayon::bold('Harmonize data on public holidays\n')))

library(here); library(glue)
library(dplyr)
library(lubridate)

# Constants -------------------------------------------------------

wd <- here()

# Data ------------------------------------------------------------

load(glue('{wd}/build/data_skeleton/skeleton.Rdata'))
load(glue('{wd}/build/data_raw/holiday/national_holiday.Rdata'))

# Harmonize -------------------------------------------------------

harmonized_holiday <-
  national_holiday %>%
  select(
    nation_iso = nation_iso,
    date = date,
    holiday = name
  ) %>%
  mutate(
    year = isoyear(date),
    week = isoweek(date)
  )

# Join ------------------------------------------------------------

# if multiple public holidays occur in a single week,
# keep only the single holiday that comes first. if multiple
# holidays fall on the same day, keep only the first in order of
# occurrence.
harmonized_holiday_single_event_per_week <-
  # select 1 event per week
  harmonized_holiday %>%
  arrange(nation_iso, year, week) %>%
  group_by(nation_iso, year, week) %>%
  slice(1) %>%
  # prepare for join
  select(-date) %>%
  ungroup() %>%
  mutate(across(c(year, week), as.integer))

# join holidays with skeleton
holiday <-
  skeleton %>%
  mutate(nation_iso = substr(region_iso, 1, 2)) %>%
  left_join(
    harmonized_holiday_single_event_per_week,
    by = c('nation_iso', 'year', 'week')
  )

# distinguish between holiday unknown and no holiday
# is nation-year in harmonized holiday?
# if so holiday = 'none'
# if not holiday = NA
holiday <-
  holiday %>%
  mutate(
    holiday =
      ifelse(
        is.na(holiday) &
          nation_iso %in% harmonized_holiday$nation_iso &
          year %in% harmonized_holiday$year,
        'none', holiday
      )
  ) %>%
  select(-nation_iso)

# Export ----------------------------------------------------------

save(holiday, file = glue('{wd}/build/data_harmonized/holiday.Rdata'))
