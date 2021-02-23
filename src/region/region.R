# Add region specific meta to skeleton

# Init ------------------------------------------------------------

cat(crayon::blue(crayon::bold('Add region specific meta to skeleton\n')))

library(here); library(glue)
library(readr); library(dplyr)

# Constants -------------------------------------------------------

wd <- here()

region_meta <- read_csv(glue('{wd}/src/global/region_metadata.csv'))

# Data ------------------------------------------------------------

load(glue('{wd}/build/data_skeleton/skeleton.Rdata'))

# Add info on regions ---------------------------------------------

region_meta_to_join <-
  region_meta %>%
  select(
    region_iso = region_code_iso3166_2,
    region_name = region_name,
    region_level = region_level,
    country_iso = region_code_iso3166_1,
    country_name = country_name,
    hemisphere = hemisphere,
    continent = continent
  )

region <-
  left_join(skeleton, region_meta_to_join, by = 'region_iso')

# Export ----------------------------------------------------------

save(region, file = glue('{wd}/build/data_harmonized/region.Rdata'))
