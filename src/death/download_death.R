# Download data on death counts

# Init ------------------------------------------------------------

cat(crayon::blue(crayon::bold('Download death data\n')))

library(here); library(glue)
library(readr); library(dplyr)

# Constants -------------------------------------------------------

wd <- here()

# Download --------------------------------------------------------

stmf <-
  read_csv(
    'https://www.mortality.org/Public/STMF/Outputs/stmf.csv',
    col_types = "ciicddddddddddddlll",
    skip = 2, col_names = TRUE
  )

# Export ----------------------------------------------------------

save(stmf, file = glue('{wd}/build/data_raw/death/stmf.Rdata'))
