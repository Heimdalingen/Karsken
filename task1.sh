#!/bin/bash

# Fetch the current temperature for given coordinates
get_temperature() {
    local latitude="$1"
    local longitude="$2"
    curl -s "https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current_weather=true&temperature_unit=celsius&timezone=auto" \
        | jq -r '.current_weather.temperature'
}

# Download city data and load into an associative array
load_cities() {
    local url="https://chanyas.folk.ntnu.no/norway/norwegiancities.txt"
    local file="norwegiancities.txt"

    # Download the file from the URL
    curl -s -o "$file" "$url"

    # Read the file and populate the associative array
    declare -gA cities
    while IFS=',' read -r city latitude longitude; do
        cities["$city"]="$latitude $longitude"
    done < <(cat "$file")
}

# Play the guessing game
play_game() {
    # Select a random city
    selected_city=$(shuf -e "${!cities[@]}" -n 1)
    read latitude longitude <<<"${cities[$selected_city]}"

    # Fetch the actual temperature
    actual_temperature=$(get_temperature "$latitude" "$longitude")

    # Introduction
    echo "Welcome to the Weather Guessing Game!"
    echo "City: $selected_city. Guess its current temperature (in Celsius)."
    echo "Hint: The temperature is between -5°C and 5°C. You have 3 attempts!"

    # Game loop
    for attempt in {1..3}; do
        read -p "Attempt $attempt: Enter your guess or type 'give up': " guess

        # Check if the user gave up
        if [[ "$guess" == "give up" ]]; then
            echo "You gave up! The actual temperature in $selected_city was $actual_temperature°C."
            return
        fi

        # Validate input and calculate the difference
        if [[ "$guess" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            difference=$(awk "BEGIN {print $actual_temperature - $guess}")
            abs_difference=$(awk "BEGIN {print ($difference < 0) ? -$difference : $difference}")

            if (( $(awk "BEGIN {print ($abs_difference <= 3) ? 1 : 0}") )); then
                echo "Correct! The actual temperature in $selected_city is $actual_temperature°C."
                return
            fi

            echo "Your guess is too $( [[ $(awk "BEGIN {print ($difference > 0) ? 1 : 0}") == 1 ]] && echo "low" || echo "high" ). Try again!"
        else
            echo "Invalid input. Please enter a number or 'give up'."
        fi
    done

    # If user fails all attempts
    echo "Out of attempts! The actual temperature in $selected_city was $actual_temperature°C."
}

# Main script
load_cities

while true; do
    play_game
    read -p "Play again? (y/n): " play_again
    [[ "$play_again" =~ ^[yY]$ ]] || break
done

echo "Goodbye! Thanks for playing."
