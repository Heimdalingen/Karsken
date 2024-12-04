#!/bin/bash

# Main Monitoring Script
output_file="/home/chanyas/Documents/cronweather/output.log"
game_url="http://localhost/cgi-bin/Weathergame.sh"
leaderboard_file="/var/www/eksamen/Weather_game/scores.txt"

# Start of Health Check
echo "=== System Health Check at $(date) ===" >> "$output_file"

# Run Disk Space Script
if /home/chanyas/Documents/cronweather/diskspace.sh >> "$output_file" 2>&1; then
    echo "Disk space check completed successfully." >> "$output_file"
else
    echo "Disk space check failed!" >> "$output_file"
fi

# Run CPU Usage Script
if /home/chanyas/Documents/cronweather/cpu.sh >> "$output_file" 2>&1; then
    echo "CPU usage check completed successfully." >> "$output_file"
else
    echo "CPU usage check failed!" >> "$output_file"
fi

# Run Weather Data Script
if /home/chanyas/Documents/cronweather/weatherfiles.sh >> "$output_file" 2>&1; then
    echo "Weather data check completed successfully." >> "$output_file"
else
    echo "Weather data check failed!" >> "$output_file"
fi

# Check if leaderboard file exists and is writable
echo "=== Checking Leaderboard File ===" >> "$output_file"
if [ -f "$leaderboard_file" ]; then
    if [ -w "$leaderboard_file" ]; then
        echo "Leaderboard file exists and is writable." >> "$output_file"
    else
        echo "Leaderboard file exists but is NOT writable. Check permissions!" >> "$output_file"
    fi
else
    echo "Leaderboard file does not exist! Creating a new one..." >> "$output_file"
    if touch "$leaderboard_file" && chmod 664 "$leaderboard_file"; then
        echo "New leaderboard file created successfully." >> "$output_file"
    else
        echo "Failed to create leaderboard file! Check directory permissions." >> "$output_file"
    fi
fi

# Check Weather Game Service
echo "=== Checking Weather Game Service ===" >> "$output_file"
response=$(curl -s -o /dev/null -w "%{http_code}" "$game_url")
if [[ "$response" == "200" ]]; then
    echo "Weather Game is accessible and functioning correctly." >> "$output_file"
else
    echo "Weather Game is not accessible. HTTP status code: $response" >> "$output_file"
    echo "Check the server or game script for issues." >> "$output_file"
fi

# End of Health Check
echo "=== End of Health Check ===" >> "$output_file"
echo "" >> "$output_file"
