#!/bin/bash

current_path=$(pwd)/src/holiday

# run a docker file which presents a holiday-date API at localhost:80
# https://github.com/nager/Nager.Date
sudo docker run -d -e "EnableCors=true" -e "EnableIpRateLimiting=false" -e "EnableSwaggerMode=true" -p 80:80 nager/nager-date:build-25 & sleep 7

# run the R script that checks dates against the docker public holiday api
Rscript --vanilla $current_path/download_holiday.R
