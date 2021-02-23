# Harmonize data on death counts

# Init ------------------------------------------------------------

cat(crayon::blue(crayon::bold('Harmonize data on death counts\n')))

library(here); library(glue)
library(yaml)
library(readr); library(dplyr); library(tidyr)

# Constants -------------------------------------------------------

wd <- here()

config <- read_yaml(glue('{wd}/src/global/config.yaml'))
region_meta <- read_csv(glue('{wd}/src/global/region_metadata.csv'))

# lookup tables to translate STMF codes to harmonized codes
cnst <- list(
  sex =
    c(m = config$skeleton$sex$Male, f = config$skeleton$sex$Female),
  age =
    c(`0_14` = config$skeleton$age$`[0,15)`,
      `15_64` = config$skeleton$age$`[15,65)`,
      `65_74` = config$skeleton$age$`[65,75)`,
      `75_84` = config$skeleton$age$`[75,85)`,
      `85p` = config$skeleton$age$`85+`),
  # STMF region codes for regions specified in config
  region_codes = 
    region_meta %>%
    filter(region_code_iso3166_2 %in% config$skeleton$region) %>%
    select(region_code_iso3166_2, region_code_stmf),
  region_iso = region_meta$region_code_iso3166_2
)

# Functions -------------------------------------------------------

source(glue('{wd}/src/global/funs.R'))

# Data ------------------------------------------------------------

load(glue('{wd}/build/data_skeleton/skeleton.Rdata'))
load(glue('{wd}/build/data_raw/death/stmf.Rdata'))

# Harmonize -------------------------------------------------------

harmonized_stmf <-
  stmf %>%
  select(
    region_stmf = CountryCode,
    year = Year, week = Week,
    sex = Sex,
    D0_14:D85p,
  ) %>%
  pivot_longer(
    cols = D0_14:D85p,
    names_sep = 1,
    names_to = c('statistic', 'age_group'),
    values_to = 'deaths'
  ) %>%
  mutate(
    sex =
      factor(sex, levels = names(cnst$sex), labels = cnst$sex) %>%
      as.character(),
    age_start = 
      factor(age_group, names(cnst$age), cnst$age) %>%
      as.character() %>% as.numeric(),
    region_iso =
      factor(region_stmf,
             levels = cnst$region_codes$region_code_stmf,
             labels = cnst$region_codes$region_code_iso3166_2) %>%
      as.character()
  ) %>%
  mutate(
    id = GenerateRowID(region_iso = region_iso,
                       sex = sex, age_start = age_start,
                       year = year, week = week)
  ) %>%
  select(id, deaths)

# Join ------------------------------------------------------------

death <-
  left_join(skeleton, harmonized_stmf, by = 'id')

# Export ----------------------------------------------------------

save(death, file = glue('{wd}/build/data_harmonized/death.Rdata'))
