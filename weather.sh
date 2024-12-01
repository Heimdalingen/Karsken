#!/bin/bash

#SCRIPT4: Running the weather using json. 
# Define file locations
output_file="/home/chanyas/Documents/cronweather/output.log"
weather_file="/home/chanyas/Documents/cronweather/weather.json"

# Log weather data
echo "=== Weather Data at $(date) ===" >> "$output_file"

# Check if the JSON file exists
if [[ -f "$weather_file" ]]; then
  # Extract weather information for each city
  jq -c '.[]' "$weather_file" | while read -r city_data; do
    city=$(echo "$city_data" | jq -r '.city')
    temperature=$(echo "$city_data" | jq -r '.weather.current_weather.temperature')
    windspeed=$(echo "$city_data" | jq -r '.weather.current_weather.windspeed')
    winddirection=$(echo "$city_data" | jq -r '.weather.current_weather.winddirection')
    is_day=$(echo "$city_data" | jq -r '.weather.current_weather.is_day')

    # Handle cases with missing or corrupted data
    if [[ "$temperature" == "null" || "$windspeed" == "null" || "$winddirection" == "null" ]]; then
      echo "City: $city - Weather data unavailable or corrupted" >> "$output_file"
    else
      day_or_night=$([[ "$is_day" == "1" ]] && echo "Day" || echo "Night")
      echo "City: $city | Temp: $temperatureC | Wind: $windspeed km/h @ $winddirectionï¿½ | Time: $day_or_night" >> "$output_file"
    fi
  done
else
  echo "Weather file not found: $weather_file" >> "$output_file"
fi

echo "" >> "$output_file"  # Add blank line for readability
