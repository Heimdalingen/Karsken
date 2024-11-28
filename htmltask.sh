#!/bin/bash
echo "Content-type: text/html"
echo ""

# Function to fetch the current temperature using the Open Meteo API
get_temperature() {
    local lat="$1" lon="$2"
    curl -s "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&temperature_unit=celsius&timezone=auto" | \
        sed -n 's/.*"temperature":\([0-9.-]*\).*/\1/p'
}

# Function to load city data and populate the cities associative array
load_info() {
    curl -s -o "norwegiancities.txt" "https://chanyas.folk.ntnu.no/norway/norwegiancities.txt" || { echo "<h1>Error</h1><p>Unable to download city data.</p>"; exit 1; }
    declare -gA cities
    while IFS=',' read -r city lat lon; do
        cities["$city"]="$lat $lon"
    done < "norwegiancities.txt"
}

# Read the form data (using POST)
read -r POST_DATA

# Extract the guess parameter from the form submission
guess=$(echo "$POST_DATA" | sed -n 's/^.*guess=\([^&]*\).*$/\1/p' | sed 's/%20/ /g')

# Handle empty guess (if the form is submitted without input)
if [ -z "$guess" ]; then
    echo "<h1>Error</h1><p>Please provide a valid guess.</p>"
    exit 1
fi

# Function to render the HTML form
render_form() {
    echo "
    <!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Weather Guessing Game</title>
    </head>
    <body>
        <h1>Welcome to the Weather Guessing Game!</h1>
        <p>Guess the current temperature in a random Norwegian city.</p>
        
        <!-- Display the result from the game -->
        <form action='/weathergame.sh' method='post'>
            <label for='guess'>Your Guess (°C):</label>
            <input type='number' id='guess' name='guess' step='any' required>
            <input type='submit' value='Submit Guess'>
        </form>
    "

    # Display the game result
    if [[ "$guess" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        # Load city data and select a random city
        load_cities
        city=$(shuf -e "${!cities[@]}" -n 1)
        read lat lon <<<"${cities[$city]}"
        actual_temp=$(get_temperature "$lat" "$lon")

        # Calculate the difference between the guess and actual temperature
        difference=$(echo "$actual_temp - $guess" | bc)
        abs_diff=$(echo "$difference" | awk '{print ($1 < 0) ? -$1 : $1}')
        
        # Check if the guess is close enough to the actual temperature
        if (( $(echo "$abs_diff <= 3" | bc -l) )); then
            echo "<h1>Correct!</h1><p>The actual temperature in $city was $actual_temp°C.</p>"
        else
            echo "<h1>Wrong Guess!</h1><p>Your guess was off by $abs_diff°C. The correct temperature was $actual_temp°C in $city.</p>"
        fi
    else
        # If the guess is invalid
        echo "<h1>Invalid Input</h1><p>Please enter a valid number for your guess.</p>"
    fi

    # Close the HTML structure
    echo "
        <hr>
        <h2>Game Instructions:</h2>
        <ul>
            <li>Try to guess the temperature in a random city.</li>
            <li>If you are unsure, you can give up.</li>
        </ul>
        <footer>
            <p>Good luck!</p>
        </footer>
    </body>
    </html>"
}

# Call the function to render the HTML page
render_form
