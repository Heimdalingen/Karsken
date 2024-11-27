#!/bin/bash

# The main function for fetching data and information 
get_temperature() {
    local latitude="$1"
    local longitude="$2"

    # Fetch the weather data (temperature)
    local response=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current_weather=true&temperature_unit=celsius&timezone=auto")
    echo "$response" | jq -r '.current_weather.temperature'
}

# Download the cities file
URL="https://chanyas.folk.ntnu.no/cities/citiesinnorway.txt"
OUTPUT_FILE="citiesinnorway.txt"
curl -s -o "$OUTPUT_FILE" "$URL"

# Load cities from the file using `cat` 
declare -A cities
cat "$OUTPUT_FILE" | while IFS=',' read -r city latitude longitude; do
    cities["$city"]="$latitude $longitude"
done

# Function to play the temperature guessing game
play_game() {
    # Select a random city
    selected_city=$(shuf -e "${!cities[@]}" -n 1)
    read latitude longitude <<<"${cities[$selected_city]}"

    # Get the actual temperature
    actual_temperature=$(get_temperature "$latitude" "$longitude")

    # Game introduction
    echo -e "Welcome to the Karsken Weather guessing game!"
    echo "I have selected a random Norwegian city: $selected_city."
    echo "Guess its current temperature (in Celsius). You have 3 attempts!"
    echo "Hint: The temperature is between -5°C and 5°C."

    # Game attempts
    for attempt in {1..3}; do
        read -p "Attempt $attempt: Enter your guess or type 'give up': " guess

        # when chosen 'give up': 
        if [[ "$guess" == "give up" ]]; then
            echo "You gave up! The actual temperature in $selected_city was $actual_temperature°C."
            return
        fi

        # Validate the guess and calculate difference
        if [[ "$guess" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
            difference=$(echo "$actual_temperature - $guess" | bc)
            ab_difference=$(echo "${difference#-}") # Absolute value

            if (( $(echo "$ab_difference <= 3" | bc -l) )); then
                echo "Congratulations! You guessed within 3 degrees. The actual temperature in $selected_city is $actual_temperature°C."
                return
            fi
            echo "Your guess is too $( [[ $difference > 0 ]] && echo "low" || echo "high" ). Try again!"
        else
            echo "Please enter a valid number or 'give up'."
        fi
    done

    # Out of attempts
    echo "Sorry, you lost! The actual temperature in $selected_city was $actual_temperature°C."
}

# Main game loop 
while true; do
    play_game
    read -p "Do you want to play again? (y/n): " play_again
    [[ "$play_again" != [yY] ]] && break
done

echo "Goodbye! Thanks for playing."
