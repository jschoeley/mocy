# Download data on public holidays

# Init ------------------------------------------------------------

cat(crayon::blue(crayon::bold('Download holiday data\n')))

library(here); library(glue)
library(yaml); library(jsonlite)
library(readr); library(dplyr); library(purrr)

# Constants -------------------------------------------------------

wd <- here()

source(glue('{wd}/src/global/funs.R'))

config <- read_yaml(glue('{wd}/src/global/config.yaml'))
region_meta <- read_csv(glue('{wd}/src/global/region_metadata.csv'))

cnst <- list(
  # local docker image of public holiday api documented at
  # https://github.com/nager/Nager.Date
  holiday_api = 'http://localhost/Api/v2/PublicHolidays'
)

# Data ------------------------------------------------------------

load(glue('{wd}/build/data_skeleton/skeleton.Rdata'))

# Download --------------------------------------------------------

holiday_skeleton <-
  skeleton %>%
  # for sub-national regions simply consider the nation when inferring
  # holidays
  mutate(nation_iso = substr(region_iso, 1, 2)) %>%
  select(nation_iso, year) %>%
  unique()

# download holiday info
holiday_raw <-
  pmap(
    holiday_skeleton, ~{
      # ..1: nation_iso
      # ..2: year
      cat(crayon::blue('Download holiday for ', ..1, ..2, '\n'))
      tryCatch(
        fromJSON(glue('{cnst$holiday_api}/{..2}/{..1}')),
        error = function (x) {NA}
      )
    })
names(holiday_raw) <- unlist(pmap(holiday_skeleton, ~{paste0(..1, ..2)}))

# Filter and bind -------------------------------------------------

national_holiday <-
  holiday_raw[!is.na(holiday_raw)] %>%
  map(~{
    .x %>%
      # only keep public & nation-wide holidays
      filter(global == TRUE, type == 'Public') %>%
      select(date, nation_iso = countryCode, name)
  }) %>%
  bind_rows()

# Export ----------------------------------------------------------

save(national_holiday, file = glue('{wd}/build/data_raw/holiday/national_holiday.Rdata'))
