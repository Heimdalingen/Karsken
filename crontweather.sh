#!/bin/bash

#CRONTAB
#THE MAIN SCRIPT TO RUN EVERYTHING

# Define log file locations and cities file
output_file="/home/chanyas/Documents/cronweather/output.log"
cities_file="/home/chanyas/Documents/cronweather/norwegiancities.txt"

# Log start of the script
echo "=== Script started at $(date) ===" >> "$output_file"

#CPU
/home/chanyas/Documents/cronweather/cpu.sh

#DISK
/home/chanyas/Documents/cronweather/diskspace.sh

#WEATHER
/home/chanyas/Documents/cronweather/weatherfiles.sh

# Log end of the script
echo "=== Script completed at $(date) ===" >> "$output_file"
