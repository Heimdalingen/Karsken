#!/bin/bash

#SCRIPT2: DISKSPACE

# Define log file location
output_file="/home/chanyas/Documents/cronweather/output.log"

# Log Disk Space
echo "=== Disk Space at $(date) ===" >> "$output_file"
df -h / | awk 'NR==1 || NR==2' >> "$output_file"
echo "" >> "$output_file"  # Add blank line for readability
