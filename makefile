# Build the MOCY data base

### EXECUTABLES --------------------------------------------------------

MD := mkdir -p
R := Rscript --vanilla

### PATHS --------------------------------------------------------------

PWD_PATH := $(shell pwd)

SOURCE_PATH := $(PWD_PATH)/src

BUILD_PATH := $(PWD_PATH)/build
CACHE_PATH := $(BUILD_PATH)/cache
MARKER_PATH := $(BUILD_PATH)/marker
DATA_SKELETON_PATH := $(BUILD_PATH)/data_skeleton
DATA_RAW_PATH := $(BUILD_PATH)/data_raw
DATA_HARMONIZED_PATH := $(BUILD_PATH)/data_harmonized

OUT_PATH := $(PWD_PATH)/out

DIRS_TO_CREATE := $(BUILD_PATH) $(CACHE_PATH) $(MARKER_PATH) $(DATA_SKELETON_PATH) $(DATA_RAW_PATH) $(DATA_HARMONIZED_PATH) $(OUT_PATH)

### CREATE BASIC FOLDER STRUCTURE --------------------------------------

$(shell $(MD) $(DIRS_TO_CREATE))

### INIT ---------------------------------------------------------------

# download and install some dependencies
init: $(MARKER_PATH)/init
$(MARKER_PATH)/init:
	# install and update r packages
	$(R) $(SOURCE_PATH)/init/install_r_dependencies.R
	# install nager date server docker
	$(SOURCE_PATH)/init/install_nager_date_server_docker.sh
	touch $@

### SKELETON -----------------------------------------------------------

# build a the skeleton for the mocy data base
skeleton: $(MARKER_PATH)/skeleton
$(MARKER_PATH)/skeleton: $(MARKER_PATH)/init
	$(R) $(SOURCE_PATH)/skeleton/skeleton.R
	touch $@

### DOWNLOAD -----------------------------------------------------------

# download raw data
download: download_death download_population download_holiday download_weather

download_death: $(MARKER_PATH)/download_death
$(MARKER_PATH)/download_death: $(MARKER_PATH)/init $(MARKER_PATH)/skeleton
	$(MD) $(DATA_RAW_PATH)/death
	$(R) $(SOURCE_PATH)/death/download_death.R
	touch $@

download_population: $(MARKER_PATH)/download_population
$(MARKER_PATH)/download_population: $(MARKER_PATH)/init $(MARKER_PATH)/skeleton
	$(MD) $(DATA_RAW_PATH)/population
	$(R) $(SOURCE_PATH)/population/download_population.R
	touch $@

download_holiday: $(MARKER_PATH)/download_holiday
$(MARKER_PATH)/download_holiday: $(MARKER_PATH)/init $(MARKER_PATH)/skeleton
	$(MD) $(DATA_RAW_PATH)/holiday
	$(SOURCE_PATH)/holiday/download_holiday.sh
	touch $@

download_weather: $(MARKER_PATH)/download_weather
$(MARKER_PATH)/download_weather: $(MARKER_PATH)/init $(MARKER_PATH)/skeleton
	$(MD) $(DATA_RAW_PATH)/weather
	$(R) $(SOURCE_PATH)/weather/download_gridded_population.R
	$(R) $(SOURCE_PATH)/weather/download_gridded_daily_temperature.R
	touch $@

### HARMONIZE ----------------------------------------------------------

harmonize: harmonize_death harmonize_population harmonize_holiday harmonize_weather harmonize_region

harmonize_death: $(MARKER_PATH)/harmonize_death
$(MARKER_PATH)/harmonize_death: $(MARKER_PATH)/download_death
	$(R) $(SOURCE_PATH)/death/harmonize_death.R
	touch $@

harmonize_population: $(MARKER_PATH)/harmonize_population
$(MARKER_PATH)/harmonize_population: $(MARKER_PATH)/download_population
	$(R) $(SOURCE_PATH)/population/harmonize_population.R
	touch $@

harmonize_holiday: $(MARKER_PATH)/harmonize_holiday
$(MARKER_PATH)/harmonize_holiday: $(MARKER_PATH)/download_holiday
	$(R) $(SOURCE_PATH)/holiday/harmonize_holiday.R
	touch $@

harmonize_weather: $(MARKER_PATH)/harmonize_weather
$(MARKER_PATH)/harmonize_weather: $(MARKER_PATH)/download_weather
	$(R) $(SOURCE_PATH)/weather/global_temperature_grid_to_weekly_series_by_country.R
	$(R) $(SOURCE_PATH)/weather/harmonize_weather_data.R
	touch $@

harmonize_region: $(MARKER_PATH)/harmonize_region
$(MARKER_PATH)/harmonize_region:
	$(R) $(SOURCE_PATH)/region/region.R
	touch $@

### ASSEMBLE -----------------------------------------------------------

join: $(MARKER_PATH)/join
$(MARKER_PATH)/join: $(MARKER_PATH)/harmonize_death $(MARKER_PATH)/harmonize_population $(MARKER_PATH)/harmonize_holiday $(MARKER_PATH)/harmonize_weather $(MARKER_PATH)/harmonize_region
	$(R) $(SOURCE_PATH)/join/join.R
	touch $@

test: join
	$(R) $(SOURCE_PATH)/test/test.R

all: join test

### CLEAN --------------------------------------------------------------

# remove build files
clean:
	rm -r $(BUILD_PATH)
	rm -r $(OUT_PATH)
