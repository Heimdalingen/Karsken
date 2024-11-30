#!/bin/bash

#SCRIPT3: CPU 

# Define log file location
output_file="/home/chanyas/Documents/cronweather/output.log"

# Log CPU Usage
echo "=== CPU Usage at $(date) ===" >> "$output_file"
top -b -n1 | awk '/^%Cpu/ {print "CPU Usage: " $2 + $4 "%"}' >> "$output_file"
echo "" >> "$output_file"  
