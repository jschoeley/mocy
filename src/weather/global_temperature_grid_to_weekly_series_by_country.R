# Prepare temperature data

# Init ------------------------------------------------------------

cat(crayon::blue(crayon::bold('Prepare temperature data/n')))

#memory.limit(60e3)

library(here); library(glue)
library(ncdf4); library(abind)
library(readr); library(yaml)
library(dplyr); library(tidyr); library(stringr)
library(lubridate); library(ggplot2)

dat <- list()

# Constants -------------------------------------------------------

#wd <- '/home/jon/lucile/share/Dropbox/sci/2020-12-mocy'
wd <- here()

config <- read_yaml(glue('{wd}/src/global/config.yaml'))

cnst <- list()
cnst <- within(cnst, {
  
  # all files relevant for creation of data set
  files = list.files(
    c(
      glue('{wd}/build/data_raw/weather/')
    )
  )
  # daily maximum temperature files
  tmax_files = str_subset(files, 'tmax\\.\\d{4}\\.nc')
  # daily minimum temperature files
  tmin_files = str_subset(files, 'tmin\\.\\d{4}\\.nc')
  # long term mean maximum and minimum temperature files
  tltm_max_file = 'tmax.day.1981-2010.ltm.nc'
  tltm_min_file = 'tmin.day.1981-2010.ltm.nc'
  # gridded population count files
  gridded_population_file = 'gpw_v4_population_count_rev11_30_min.nc'
  # gridded population metadata files
  gridded_population_metadata = 'gpw_v4_national_identifier_grid_rev11_lookup.txt'
  
  # number of years
  n_year = length(tmin_files)
  # origin date
  origin_date = date('2000-01-01')
  
  # longitude and latitude coordinates over array x,y dimensions
  # (for use with temperature grid)
  lon =
    # coordinates as given in the data
    seq(0.25, 359.75, 0.5) %>%
    # convert to longitude centered at Greenwich
    {ifelse(. > 180, -360+., .)}
  lat =
    seq(89.75, -89.75, -0.5)
  # (for use with population and national id grid)
  lon2 =
    seq(-179.75, 179.75, 0.5)
  lat2 =
    seq(89.75, -89.75, -0.5)
  # indices of lon2 in lon1
  lon2tolon1 =
    c(which(lon2==0.25):length(lon2),
      1:which(lon2==-0.25))
  
})

# Function --------------------------------------------------------

source(glue('{wd}/src/global/funs.R'))

# Prepare national identifier grid --------------------------------

nat <- list()

# national identifier grid
nat$nat_nc <- nc_open(
  glue('{wd}/build/data_raw/weather/{cnst$gridded_population_file}')
)

# national identifier grid
nat$nat_array <- ncvar_get(nat$nat_nc, 'Population Count, v4.11 (2000, 2005, 2010, 2015, 2020): 30 arc-minutes')
# subset to national identifier grid
nat$nat_array <- nat$nat_array[,,11]
dimnames(nat$nat_array) <- list(lon = cnst$lon2, lat = cnst$lat2)

# reorder array so that greenwich longitude is at x=0
# this is to harmonize the format with the temperature data
nat_array <- nat$nat_array[cnst$lon2tolon1,]
#image(nat_array)

# cache data for use later
save(nat_array, file = glue('{wd}/build/cache/nat_array.Rdata'))

# clean
rm(nat, nat_array)

# Prepare population grid -----------------------------------------

pop <- list()

# gridded population
pop$pop_nc <- nc_open(
  glue('{wd}/build/data_raw/weather/{cnst$gridded_population_file}')
)

# population data
# convert to array, select population 2010, and convert to
# long format data frame
# pop array
pop$pop_array <- ncvar_get(pop$pop_nc, 'Population Count, v4.11 (2000, 2005, 2010, 2015, 2020): 30 arc-minutes')
# subset to population count 2010
pop$pop_array <- pop$pop_array[,,3]
dimnames(pop$pop_array) <- list(lon = cnst$lon2, lat = cnst$lat2)

# reorder array so that greenwich longitude is at x=0
# this is to harmonize the format with the temperature data
pop_array <- pop$pop_array[cnst$lon2tolon1,]

# test
#image(pop_array)

# cache data for use later
save(pop_array, file = glue('{wd}/build/cache/pop_array.Rdata'))

# clean
rm(pop, pop_array)

# Prepare weekly average temperature grid -------------------------

temp <- list()

# 1. load daily minimum and maximum temperature grids by year
# 2. calculate daily average temperature
# 3. save result in list (x: lon, y: lat, z: day of year, list_item: year)
for (i in 1:cnst$n_year) {
  cat(cnst$tmin_files[i], cnst$tmax_files[i], '\n')
  
  tmin_file <- cnst$tmin_files[i]
  tmax_file <- cnst$tmax_files[i]
  
  year <- str_extract(cnst$tmin_files[i], '\\d{4}')
  
  tmin_y <- nc_open(
    glue('{wd}/build/data_raw/weather/{tmin_file}')
  )
  tmax_y <- nc_open(
    glue('{wd}/build/data_raw/weather/{tmax_file}')
  )

  # min array
  tmin_y_array <-
    ncvar_get(tmin_y, 'tmin')
  dimnames(tmin_y_array) <-
    list(lon = cnst$lon, lat = cnst$lat, day = 1:dim(tmin_y_array)[3])
  
  # max array
  tmax_y_array <-
    ncvar_get(tmax_y, 'tmax')
  dimnames(tmax_y_array) <-
    list(lon = cnst$lon, lat = cnst$lat, day = 1:dim(tmax_y_array)[3])
  
  # approximate average daily temperature
  tavg_y_array <- (tmax_y_array + tmin_y_array) / 2
  
  temp$t_avg[[year]] <- tavg_y_array
  
}; rm(tavg_y_array, tmax_y_array,
      tmin_y_array, tmax_y, tmin_y,
      tmin_file, tmax_file, year, i)

# bind all years into a single 3D array where the z axis
# marks the days since 2020-01-01 minus 1
temp$t_avg <- abind(temp$t_avg, along = 3)

# annotate the 3d array with iso-year-week calendar
# multiple days will be situated in the same week
temp$dates <- cnst$origin_date + ((1:dim(temp$t_avg)[3])-1)
dimnames(temp$t_avg)[[3]] <-
  Date2ISOWeek(temp$dates, format = 'iso') %>% str_sub(1, 8)

# average daily temperatures into weeks
temp$year_week <- unique(dimnames(temp$t_avg)[[3]])
temp$n_year_week <- length(temp$year_week)
tyw_array <-
  array(
    dim = c(dim(temp$t_avg)[1:2], temp$n_year_week),
    dimnames = list(lon = cnst$lon, lat = cnst$lat, yearweek = temp$year_week)
  )
for (week_i in 1:temp$n_year_week) {
  cat(crayon::blue(glue('Averaging global daily gridded temperature for week {temp$year_week[week_i]}')), sep = '\n')
  daily_temperature_grid_single_week <-
    temp$t_avg[,,dimnames(temp$t_avg)[[3]] %in% temp$year_week[week_i],
               drop = FALSE]
  # average over days
  tyw_array[,,week_i] <-
    rowMeans(daily_temperature_grid_single_week, na.rm = FALSE, dims = 2)
}; rm(daily_temperature_grid_single_week)

temp$t_avg <- NULL

# test
#image(tyw_array[,,500])

# cache data for use later
save(tyw_array, file = glue('{wd}/build/cache/tyw_array.Rdata'))

# clean
rm(temp, tyw_array, week_i)

# Aggregate to weekly country level average temperature -----------

load(glue('{wd}/build/cache/nat_array.Rdata'))
load(glue('{wd}/build/cache/pop_array.Rdata'))
load(glue('{wd}/build/cache/tyw_array.Rdata'))

# for translation between numeric nation code and ISO codes
nat_lookup <-
  left_join(
    read_csv(glue('{wd}/src/global/region_metadata.csv')),
    read_tsv(glue('{wd}/build/data_raw/weather/{cnst$gridded_population_metadata}')) %>%
      select(ISOCODE, Value),
    by = c('region_code_iso3166_1_alpha3'= 'ISOCODE')
  )

# the land mask changes over the years, this harmonizes the land
# mask to the one with lowest coverage
# it seems like areas near the coast got added in later years
# the final mask still has some problems inheriting from the
# uneven land mask definition:
# - caspian sea is defined as land
# - tasmania is missing
# - new zealand is missing
harmonization_mask <-
  rowSums(tyw_array, dims = 2, na.rm = FALSE)
harmonization_mask[!is.na(harmonization_mask)] <- 1

# indices
country_codes <- unique(nat_lookup$Value)
country_names <- unique(nat_lookup$region_code_iso3166_1)
country_index <- 1:length(country_codes)
week_index <- 1:dim(tyw_array)[3]
# 3D array weeks x country x statistic
country_timeseries <- array(
  NA,
  dim = c(length(week_index), length(country_index), 2),
  dimnames = list(
    week_index, country_names, c('traw', 'twgt')
  )
)
# 
for (cntry_i in country_index) {
  
  # a mask with 1 for grid cells covering the current country and
  # NA otherwise
  single_country_mask <- array(NA, dim(nat_array))
  single_country_mask[
    which(nat_array == country_codes[cntry_i], arr.ind = TRUE)
  ] <- 1

  single_country_total_population <-
    sum(harmonization_mask*single_country_mask*pop_array, na.rm = TRUE)
  n_country_pixels <- sum(single_country_mask, na.rm = TRUE)
  mask <- harmonization_mask*single_country_mask
  
  for (week_i in week_index) {
    
    cat(crayon::blue(glue('Averaging weekly temperature for country {country_names[cntry_i]} {week_i}')), sep = '\n')
    
    # average temperature by year-week and country
    x <- mask*tyw_array[,,week_i]
    country_timeseries[week_i,cntry_i,'traw'] <-
      sum(x/n_country_pixels, na.rm = TRUE)
    if (all(is.na(x))) {country_timeseries[week_i,cntry_i,'traw'] <- NA}
    # population weighted average temperature by year-week and country
    x <- mask*pop_array*tyw_array[,,week_i]
    country_timeseries[week_i,cntry_i,'twgt'] <-
      sum(x/single_country_total_population, na.rm = TRUE)
    if (all(is.na(x))) {country_timeseries[week_i,cntry_i,'twgt'] <- NA}
  }
  
}

weather <-
  expand_grid(
    country_iso = country_names,
    weeks = week_index
  ) %>%
  mutate(
    date = cnst$origin_date + weeks*7 - 7,
    year = isoyear(date),
    week = isoweek(date)
  ) %>%
  mutate(
    traw = c(country_timeseries[,,'traw']),
    twgt = c(country_timeseries[,,'twgt'])
  )

# weather %>%
#   filter(year==2020) %>%
#   ggplot(aes(x = date)) +
#   geom_step(aes(y = traw)) +
#   geom_step(aes(y = twgt), color = 'red', alpha = 0.5) +
#   facet_wrap(~country_iso, scales = 'free_y') +
#   labs(y = '°C')

# cache data for use later
save(weather, file = glue('{wd}/build/cache/weather.Rdata'))
