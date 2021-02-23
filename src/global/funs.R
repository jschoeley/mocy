#' Create Unique Row ID
#'
#' @param region_iso iso-3166-1 alpha 2 country code with optional
#'   iso-3166-2 region code added, separated by a hyphen.
#' @param sex 'Male' or 'Female'
#' @param age_start Positive Integer.
#' @param year Positive Integer.
#' @param week Positive Integer.
#'
#' @return
#' String with fixed length row ID constructed from input.
#'
#' @examples
#' GenerateRowID('DE-BW', 'Male', 0, 2020, 10)
GenerateRowID <- function(region_iso, sex, age_start, year, week) {
  region_id <- sapply(region_iso, function (x) {
    expanded_region <- '------'
    substr(expanded_region, 1, nchar(x)) <- x
    return(expanded_region)
  })
  sex_id <- as.character(factor(sex, c('Male', 'Female'), c('M', 'F')))
  age_id <- sprintf('%02d', age_start)
  year_id <- sprintf('%04d', year)
  week_id <- sprintf('%02d', week)
  
  row_id <- paste0(region_id, sex_id, age_id, year_id, week_id)
  
  return(row_id)
}


#' Convert Week of Year to Date
#'
#' @param year Year integer.
#' @param week Week of year integer (1 to 53).
#' @param weekday Weekday integer (1, Monday to 7, Sunday).
#' @param offset Integer offset added to `week` before date calculation.
#'
#' @return A date object.
#'
#' @source https://en.wikipedia.org/wiki/ISO_8601
#'
#' @author Jonas Schöley
#'
#' @examples
#' # the first Week of 2020 actually starts Monday, December 30th 2019
#' ISOWeekDate2Date(2020, 1, 1)
ISOWeekDate2Date <- function (year, week, weekday = 1, offset = 0) {
  require(ISOweek)
  isoweek_string <-
    paste0(
      year, '-W',
      formatC(
        week+offset,
        flag = '0',
        format = 'd',
        digits = 1
      ),
      '-', weekday
    )
  ISOweek2date(isoweek_string)
}


#' Calculate Weeks Since Some Origin Date
#'
#' @param date Date string.
#' @param origin_date Date string.
#' @param week_format Either 'integer' for completed weeks or
#' 'fractional' for completed fractional weeks.
#'
#' @return Time difference in weeks.
#'
#' @author Jonas Schöley
#'
#' @examples
#' # My age in completed weeks
#' WeeksSinceOrigin(Sys.Date(), '1987-07-03')
WeeksSinceOrigin <-
  function(date, origin_date, week_format = "integer") {
    require(ISOweek)
    fractional_weeks_since_origin <-
      as.double(difftime(
        as.Date(date),
        as.Date(origin_date),
        units = "weeks"
      ))
    switch(
      week_format,
      fractional = fractional_weeks_since_origin,
      integer = as.integer(fractional_weeks_since_origin)
    )
  }


#' Convert Date to Week of Year
#'
#' @param date Date string.
#' @param format Either 'integer', 'iso', or 'string'.
#'
#' @return Week of year.
#' 
#' @source https://en.wikipedia.org/wiki/ISO_8601
#'
#' @author Jonas Schöley
#'
#' @examples
#' # February 2020 started in the 5th week of the year
#' Date2ISOWeek('2020-02-01', format = 'integer')
#' Date2ISOWeek('2020-02-01', format = 'iso')
#' Date2ISOWeek('2020-02-01', format = 'string')
Date2ISOWeek <- function (date, format = 'integer') {
  require(ISOweek)
  iso_week_of_year <- date2ISOweek(date)
  switch(
    format,
    iso = iso_week_of_year,
    string = substr(iso_week_of_year, 6, 8),
    integer = as.integer(substr(iso_week_of_year, 7, 8)),
  )
}