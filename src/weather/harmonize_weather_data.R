# Add weather data to skeleton

# Init ------------------------------------------------------------

cat(crayon::blue(crayon::bold('Add weather data to skeleton\n')))

library(here); library(glue)
library(readr); library(dplyr)

# Constants -------------------------------------------------------

wd <- here()

region_meta <- read_csv(glue('{wd}/src/global/region_metadata.csv'))

# Data ------------------------------------------------------------

load(glue('{wd}/build/data_skeleton/skeleton.Rdata'))
load(glue('{wd}/build/cache/weather.Rdata'))

# Add info on regions ---------------------------------------------

skeleton_merge <-
  skeleton %>% mutate(country_iso = substr(region_iso, 1, 2))

weather_data_to_join <-
  weather %>%
  mutate(across(c(traw, twgt), ~round(.x, 2))) %>%
  select(
    country_iso, year, week, temp_c_popwgt = twgt
  )

weather <-
  left_join(skeleton_merge, weather_data_to_join,
            by = c('country_iso', 'year', 'week')) %>%
  select(-country_iso)

# Export ----------------------------------------------------------

save(weather, file = glue('{wd}/build/data_harmonized/weather.Rdata'))
