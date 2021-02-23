# Derive harmonized exposures from population counts

# Init ------------------------------------------------------------

cat(crayon::blue(crayon::bold('Harmonize data on population exposures\n')))

library(here); library(glue)
library(yaml)
library(readr); library(dplyr); library(tidyr)

# Constants -------------------------------------------------------

wd <- here()

config <- read_yaml(glue('{wd}/src/global/config.yaml'))
region_meta <- read_csv(glue('{wd}/src/global/region_metadata.csv'))
source(glue('{wd}/src/global/funs.R'))

# translate HMD codes to harmonized codes
cnst <- list(
  age_breaks =
    c(config$skeleton$age, Inf),
  sex =
    c(`Male` = config$skeleton$sex$Male,
      `Female` = config$skeleton$sex$Female),
  # STMF region codes for regions specified in config
  region_codes = 
    region_meta %>%
    filter(region_code_iso3166_2 %in% config$skeleton$region) %>%
    select(region_code_iso3166_2, region_code_stmf),
  region_hmd =
    region_meta$region_code_hmd,
  region_iso =
    region_meta$region_code_iso3166_2,
  origin_date = ISOWeekDate2Date(
    year = config$skeleton$year$min,
    week = config$skeleton$week$min
  ),
  final_date = ISOWeekDate2Date(
    year = config$skeleton$year$max,
    week = config$skeleton$week$max
  )
)

# Functions -------------------------------------------------------

#' Convert population estimates to population exposures
#'
#' Converts population estimates measured at discrete points
#' in time into population exposures by interpolating between
#' the data points using a cubic spline and integrating over
#' arbitrary time intervals.
#'
#' @param df A data frame.
#' @param x Name of time variable.
#' @param P Name of population variable.
#' @param breaks_out Vector of interpolation points.
#' @param scaler Constant factor to change unit of exposures.
#' @param strata `vars()` specification of variables in df to stratify over.
#'
#' @return A data frame stratified by `strata` with population counts
#' `Px` at time `x1` and exposures `Ex` over time interval `[x1,x2)`.
#'
#' @author Jonas Schöley, José Manuel Aburto
#'
#' @examples
#' df <-
#'   expand.grid(
#'     sex = c('Male', 'Female'),
#'     age = c('[0, 80)', '80+'),
#'     quarter_week = c(1, 14, 27, 40)
#'   )
#' df$P = rnorm(16, 1e3, sd = 100)
#' Population2Exposures(
#'   df, x = quarter_week, P = P,
#'   breaks_out = 1:57, strata = vars(sex, age)
#' )
Population2Exposures <-
  function (df, x, P, breaks_out, scaler = 1, strata = NA) {
    
    require(dplyr)
    require(tidyr)
    require(purrr)
    
    x = enquo(x); P = enquo(P)
    
    # for each stratum in the data return
    #   - interpolation function
    #   - interpolated population sizes
    #   - interpolated and integrated exposures
    group_by(df, !!!strata) %>% nest() %>%
      mutate(
        # limits of time intervals
        x1 = list(head(breaks_out, -1)),
        x2 = list(breaks_out[-1]),
        # cubic spline interpolation function with linear extrapolation
        interpolation_function = map(
          data,
          ~ splinefun(x = pull(., !!x), y = pull(., !!P),
                      method = 'natural')
        ),
        # interpolated population numbers
        Px = map(
          interpolation_function,
          ~ .(x = head(breaks_out, -1))
        ),
        # interpolated and integrated population exposures
        Ex = map(
          interpolation_function,
          # closed form expression for piecewise polynomial
          # integral exists of course but implementation is
          # left for a later point
          ~ {
            fnct <- .
            map2_dbl(
              unlist(x1),
              unlist(x2),
              ~ integrate(fnct, lower = .x, upper = .y)[['value']]*scaler
            )
          }
        )
      ) %>%
      ungroup() %>%
      select(-data, -interpolation_function) %>%
      unnest(c(x1, x2, Px, Ex))
    
  }

# Data ------------------------------------------------------------

load(glue('{wd}/build/data_skeleton/skeleton.Rdata'))
load(glue('{wd}/build/data_raw/population/hmd_popjan1st.Rdata'))

# Harmonize -------------------------------------------------------

pop_jan1st <-
  hmd_popjan1st %>%
  select(
    year = Year, age = Age,
    # select January1st estimates
    Female = Female1, Male = Male1,
    region_hmd
  ) %>%
  pivot_longer(
    cols = c(Female, Male),
    names_to = 'sex',
    values_to = 'pop_jan1st'
  ) %>%
  # ensure proper names of factor variables
  mutate(
    sex =
      factor(sex, levels = names(cnst$sex), labels = cnst$sex) %>%
      as.character(),
    region_iso = factor(
      region_hmd,
      levels = cnst$region_hmd,
      labels = cnst$region_iso
    ) %>% as.character()
  ) %>%
  # aggregate to skeleton age groups
  mutate(
    age_group =
      cut(
        age,
        breaks = cnst$age_breaks,
        labels = head(cnst$age_breaks, -1),
        right = FALSE, include.lowest = TRUE
      ) %>% as.character() %>% as.integer()
  ) %>%
  group_by(region_iso, sex, year, age_group) %>%
  summarise(
    pop_jan1st = sum(pop_jan1st)
  ) %>%
  ungroup() %>%
  # add row id
  mutate(week = 1L) %>%
  mutate(id = GenerateRowID(region_iso, sex, age_group, year, week)) %>%
  select(id, pop_jan1st)

# Convert to weekly exposures -------------------------------------

# exposure in person-weeks
harmonized_population <-
  left_join(skeleton, pop_jan1st) %>%
  mutate(
    date =
      ISOWeekDate2Date(year, week),
    weeks_since_origin =
      WeeksSinceOrigin(date = date, origin_date = cnst$origin_date)
  ) %>%
  group_by(region_iso, sex, age_start) %>%
  group_modify(~{
    # integrate population sizes over 1 week intervals covering
    # the entire historical range of the data
    breaks_out = seq(min(.x$weeks_since_origin), max(.x$weeks_since_origin)+1, 1)
    # interpolation not possible if all data are NA, in that case return NA
    if (all(is.na(.x$pop_jan1st))) { Ex <- NA } else {
      Ex <- Population2Exposures(
        .x,
        x = weeks_since_origin, P = pop_jan1st,
        breaks_out = breaks_out
      ) %>%
        select(weeks_since_origin = x1, Ex) %>%
        # because the weeks since origin in the source data
        # don't always increment in unit step (week 53 is left out)
        # but the interpolated data does increment in unit step,
        # we need a join here.
        right_join(.x, by = 'weeks_since_origin') %>%
        pull(Ex)
    }
    return(.x %>% mutate(exposure = Ex))
  }) %>%
  ungroup() %>%
  mutate(across(c(exposure, pop_jan1st), ~round(.x, 2))) %>%
  select(id, personweeks = exposure, population = pop_jan1st)

# Join ------------------------------------------------------------

population <- left_join(skeleton, harmonized_population, by = 'id')

# Export ----------------------------------------------------------

save(population, file = glue('{wd}/build/data_harmonized/population.Rdata'))

