# Download gridded global population data

# Init ------------------------------------------------------------

cat(crayon::blue(crayon::bold('Download gridded global population data')), sep = '\n')

library(here); library(glue)
library(yaml); library(httr)

# Constants -------------------------------------------------------

wd <- here()

config <- read_yaml(glue('{wd}/src/global/config.yaml'))

cnst <- list(
  gridded_pop_url =
    'https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-count-rev11/gpw-v4-population-count-rev11_totpop_30_min_nc.zip',
  cache_path =
    glue('{wd}/build/cache'),
  destination_path =
    glue('{wd}/build/data_raw/weather')
)

# Download --------------------------------------------------------

GET(
  url = cnst$gridded_pop_url,
  authenticate(user = config$credentials$earthdata$user,
               password = config$credentials$earthdata$pswd),
  write_disk(glue('{cnst$cache_path}/gridded_population.zip'), overwrite = TRUE),
  progress()
)

# Export ----------------------------------------------------------

unzip(
  zipfile = glue('{cnst$cache_path}/gridded_population.zip'),
  exdir = cnst$destination_path
)
