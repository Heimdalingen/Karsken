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
    echo "Hint: The actual temperature is within the range of -5°C to 5°C."

    # Initialize attempts
    ATTEMPTS=0
    CORRECT=0
    GIVE_UP=0
    MAX_ATTEMPTS=3  # Max number of attempts set to 3

    while [ "$CORRECT" -eq 0 ] && [ "$ATTEMPTS" -lt "$MAX_ATTEMPTS" ]; do
        # Increment attempts
        ((ATTEMPTS++))

        # Prompt user for their guess or to give up
        read -p "Enter your temperature guess (°C) or type 'give up' to quit: " GUESS

        # If the user decides to give up
        if [[ "$GUESS" == "give up" ]]; then
            echo "You gave up! The actual temperature in $selected_city was $actual_temperature°C."
            GIVE_UP=1
            break
        fi

        # Check if the guess is a valid number
        if ! [[ "$GUESS" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
            echo "Please enter a valid number."
            continue
        fi

        # Calculate the temperature difference
        difference=$(echo "$actual_temperature - $GUESS" | bc)
        abs_difference=$(echo "$difference" | awk '{if($1 < 0) print -$1; else print $1}')

        # Check if the guess is within 3 degrees
        if (( $(echo "$abs_difference <= 3" | bc -l) )); then
            echo "Congratulations! You guessed within 3 degrees. The actual temperature in $selected_city is $actual_temperature°C."
            CORRECT=1
        else
            if (( $(echo "$actual_temperature > $GUESS" | bc -l) )); then
                echo "Your guess is too low! Try a higher temperature."
            else
                echo "Your guess is too high! Try a lower temperature."
            fi
        fi
    done

    # If the user didn't win, they lost
    if [ "$CORRECT" -eq 0 ] && [ "$GIVE_UP" -eq 0 ]; then
        echo "Sorry, you lost! The actual temperature in $selected_city was $actual_temperature°C."
    fi
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
