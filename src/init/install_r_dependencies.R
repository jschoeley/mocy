cat('Install R dependencies\n')

pkg_list <- c(
  'crayon',
  'here', 'glue',
  'yaml', 'readr',
  'dplyr', 'tidyr', 'stringr',
  'lubridate', 'purrr',
  'ggplot2', 'curl',
  'HMDHFDplus',
  'ISOweek',
  'ncdf4', 'abind', 'httr', 'openxlsx',
  'rmarkdown', 'xml2', 'rmarkdown', 'pander', 'tidyverse'
)

install.packages(setdiff(pkg_list, rownames(installed.packages())), repos = 'http://cran.rstudio.com/')
