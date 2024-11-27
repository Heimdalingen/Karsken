#!/bin/bash

# Function to fetch the current temperature for a given city from Open-Meteo
get_temperature() {
    local city="$1"
    local latitude="$2"
    local longitude="$3"

    # Construct the Open-Meteo API URL for current weather data
    local api_url="https://api.open-meteo.com/v1/forecast"
    local query="?latitude=${latitude}&longitude=${longitude}&current_weather=true&temperature_unit=celsius&timezone=auto"

    # Fetch the weather data (temperature)
    local response=$(curl -s "${api_url}${query}")

    # Extract the temperature from the response
    local temperature=$(echo "$response" | jq -r '.current_weather.temperature')

    # Return the temperature
    echo "$temperature"
}

# Download the cities file
URL="https://chanyas.folk.ntnu.no/cities/citiesinnorway.txt"
OUTPUT_FILE="citiesinnorway.txt"

if ! wget -q "$URL" -O "$OUTPUT_FILE"; then
    echo "Failed to download cities file. Exiting."
    exit 1
fi

# Load cities from the file
declare -A cities
while IFS=',' read -r city latitude longitude; do
    cities["$city"]="$latitude $longitude"
done < "$OUTPUT_FILE"

# Function to play the temperature guessing game
play_game() {
    # Randomly select a city
    selected_city=$(shuf -e "${!cities[@]}" -n 1)
    latitude=$(echo "${cities[$selected_city]}" | awk '{print $1}')
    longitude=$(echo "${cities[$selected_city]}" | awk '{print $2}')

    # Get the actual temperature for the selected city
    actual_temperature=$(get_temperature "$selected_city" "$latitude" "$longitude")

    # Welcome message
    echo "Welcome to the Temperature Guessing Game!"
    echo "I have selected a random Norwegian city: $selected_city."
    echo "Can you guess its current temperature (in Celsius)?"

    # Initialize attempts
    ATTEMPTS=0
    CORRECT=0

    while [ "$CORRECT" -eq 0 ]; do
        # Increment attempts
        ((ATTEMPTS++))

        # Prompt user for their guess
        read -p "Enter your temperature guess (°C): " GUESS

        # Check if the guess is a valid number
        if ! [[ "$GUESS" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
            echo "Please enter a valid number."
            continue
        fi

        # Calculate the temperature difference
        difference=$(echo "$actual_temperature - $GUESS" | bc)
        abs_difference=$(echo "$difference" | awk '{if($1 < 0) print -$1; else print $1}')

        # Check if the difference is less than or equal to 5 degrees
        if (( $(echo "$abs_difference <= 5" | bc -l) )); then
            echo "Congratulations! You guessed within 5 degrees. The actual temperature in $selected_city is $actual_temperature°C."
            CORRECT=1
        else
            echo "Your guess was off by more than 5°C. The actual temperature was $actual_temperature°C."
        fi
    done
}

# Main loop for playing again
while true; do
    # Start a new game
    play_game

    # Ask if the user wants to play again
    read -p "Do you want to play again? (y/n): " PLAY_AGAIN
    if [[ "$PLAY_AGAIN" != "y" && "$PLAY_AGAIN" != "Y" ]]; then
        echo "Goodbye! Thanks for playing."
        break
    fi
done
