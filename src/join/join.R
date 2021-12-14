# Assemble mocy data set

# Init ------------------------------------------------------------

cat(crayon::blue(crayon::bold('Assemble final data set\n')))

library(here); library(glue)
library(dplyr); library(readr); library(openxlsx)

# Constants -------------------------------------------------------

wd <- here()

# Data ------------------------------------------------------------

cat(crayon::blue('Load skeleton\n'))
load(glue('{wd}/build/data_skeleton/skeleton.Rdata'))
cat(crayon::blue('Load death\n'))
load(glue('{wd}/build/data_harmonized/death.Rdata'))
cat(crayon::blue('Load population\n'))
load(glue('{wd}/build/data_harmonized/population.Rdata'))
cat(crayon::blue('Load holiday\n'))
load(glue('{wd}/build/data_harmonized/holiday.Rdata'))
cat(crayon::blue('Load weather\n'))
load(glue('{wd}/build/data_harmonized/weather.Rdata'))
cat(crayon::blue('Load region\n'))
load(glue('{wd}/build/data_harmonized/region.Rdata'))

# Join ------------------------------------------------------------

cat(crayon::blue('Join data subsets\n'))
mocy <-
  skeleton %>% 
  left_join(region %>% select(id, region_name, region_level,
                              country_iso, country_name,
                              hemisphere, continent), by = 'id') %>%
  left_join(death %>% select(id, deaths), by = 'id') %>%
  left_join(population %>% select(id, personweeks, population), by = 'id') %>%
  left_join(holiday %>% select(id, holiday), by = 'id') %>%
  left_join(weather %>% select(id, temp_c_popwgt), by = 'id')

# Export ----------------------------------------------------------

cat(crayon::blue('Save final data set as .Rdata\n'))
save(mocy, file = glue('{wd}/out/mocy.Rdata'))

cat(crayon::blue('Save final data set as .csv\n'))
write_csv(mocy, file = glue('{wd}/out/mocy.csv'))

cat(crayon::blue('Save final data set as .xlsx\n'))
write.xlsx(mocy, glue('{wd}/out/mocy.xlsx'),
           keepNA = TRUE, na.string = '.', overwrite = TRUE,
           firstRow = TRUE, firstCol = TRUE)
