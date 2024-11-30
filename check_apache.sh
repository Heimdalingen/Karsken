#!/bin/bash

# Log file location
apache_log="/home/chanyas/Documents/cronweather/apache.log"

# Function to log Apache running status
apache_run() {
    echo "Apache is running - $(date)" >> "$apache_log"
}

# Function to log Apache not running status
apache_no() {
    echo "Apache is not running - $(date)" >> "$apache_log"
}

# Function to check if Apache is running
check_status() {
    if systemctl is-active --quiet apache2; then
        apache_run  # If Apache is running, log the status
    else
        apache_no  # If Apache is not running, log the status
    fi
}

# Run the check_apache_status function
check_status
