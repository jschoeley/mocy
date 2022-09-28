# Download data on population counts

# Init ------------------------------------------------------------

cat(crayon::blue(crayon::bold('Download population count data\n')))

library(here); library(glue)
library(yaml); library(readr)
library(HMDHFDplus)
library(dplyr); library(purrr)

# Constants -------------------------------------------------------

wd <- here()

config <- read_yaml(glue('{wd}/src/global/config.yaml'))
region_meta <- read_csv(glue('{wd}/src/global/region_metadata.csv'))

# Download --------------------------------------------------------

# hmd region codes for download
hmd_codes_for_download <- region_meta$region_code_hmd

# download HMD population january 1st estimates
# https://www.mortality.org/hmd/zip/by_statistic/population.zip
hmd_popjan1st <-
  map(hmd_codes_for_download, ~{
    cat(crayon::blue('Download population counts for ', ., '\n'))

    path <- paste0("https://former.mortality.org/hmd/", ., 
                   "/STATS/", 'Population.txt')
    TEXT <- httr::GET(
      path, httr::authenticate(config$credentials$hmd$user,
                               config$credentials$hmd$pswd), 
      httr::config(ssl_verifypeer = 0L)
    )
    single_country <- read.table(
      text = httr::content(TEXT, encoding = "UTF-8"), 
      header = TRUE, skip = 2, na.strings = ".", as.is = TRUE
    )
    single_country <- HMDparse(single_country, filepath = 'Population.txt')
    single_country$region_hmd <- .
    
    return(single_country)
  })

hmd_popjan1st <- bind_rows(hmd_popjan1st)

# Export ----------------------------------------------------------

save(hmd_popjan1st, file = glue('{wd}/build/data_raw/population/hmd_popjan1st.Rdata'))
