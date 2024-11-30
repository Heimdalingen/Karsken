#!/bin/bash
echo "Content-type: text/html"
echo ""

# File to store leaderboard data
LEADERBOARD_FILE="/var/www/eksamen/Weather_game/scores.txt"

# Function to fetch the current temperature using the Open Meteo API
get_temperature() {
    local lat="$1" lon="$2"
    curl -s "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&temperature_unit=celsius&timezone=auto" | \
        sed -n 's/.*"temperature":\([0-9.-]*\).*/\1/p'
}

# Function to load city data and populate the cities associative array
load_cities() {
    curl -s -o "/tmp/norwegiancities.txt" "https://chanyas.folk.ntnu.no/norway/norwegiancities.txt" || { echo "<h1>Error</h1><p>Unable to download city data.</p>"; exit 1; }
    declare -gA cities
    while IFS=',' read -r city lat lon; do
        cities["$city"]="$lat $lon"
    done < "/tmp/norwegiancities.txt"
}

# Function to display the leaderboard sorted by the closest guesses
display_leaderboard() {
    echo "<h2>Leaderboard</h2>"
    if [ -f "$LEADERBOARD_FILE" ]; then
        # Sort the leaderboard by the difference (5th column), in ascending order
        sorted_scores=$(sort -t',' -k5n "$LEADERBOARD_FILE")
        
        echo "<table border='1'><tr><th>Username</th><th>City</th><th>Guess (°C)</th><th>Actual Temp (°C)</th><th>Difference (°C)</th></tr>"
        while IFS=',' read -r username city guess actual_temp difference; do
            echo "<tr><td>$username</td><td>$city</td><td>$guess</td><td>$actual_temp</td><td>$difference</td></tr>"
        done <<< "$sorted_scores"
        echo "</table>"
    else
        echo "<p>No leaderboard data available.</p>"
    fi
}

# Read the form data (using POST)
read -r POST_DATA <&0

# Extract the guess, city, and username parameters from the form submission
guess=$(echo "$POST_DATA" | sed -n 's/^.*guess=\([^&]*\).*$/\1/p' | sed 's/%20/ /g')
selected_city=$(echo "$POST_DATA" | sed -n 's/^.*city=\([^&]*\).*$/\1/p' | sed 's/%20/ /g')
username=$(echo "$POST_DATA" | sed -n 's/^.*username=\([^&]*\).*$/\1/p' | sed 's/%20/ /g')

# Function to render the HTML form for submitting a guess
render_form() {
    # Load city data and select a random city
    load_cities
    city=$(shuf -e "${!cities[@]}" -n 1)
    read lat lon <<<"${cities[$city]}"

    # Render the HTML form
    echo "
    <!DOCTYPE html>
    <html lang='en'>
    <head>
        <meta charset='UTF-8'>
        <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <title>Weather Guessing Game</title>
        <style>
        /* Import Google Font - Poppins */
        @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600&display=swap');

        /* General Styles */
        body {
            font-family: 'Poppins', sans-serif;
            color: #333;
            margin: 0;
            padding: 0;
            text-align: center;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }

        /* Header */
        h1 {
            font-size: 2.5em;
            margin-top: 20px;
            color: #2c3e50;
        }

        /* Instructions Heading */
        h2 {
            font-size: 1.8em;
            color: #34495e;
            margin-top: 30px;
        }

        /* Paragraphs */
        p {
            font-size: 1.2em;
            margin: 20px auto;
            max-width: 600px;
            line-height: 1.6;
        }

        /* List Items */
        ul {
            list-style-type: none;
            padding: 0;
        }

        ul li {
            font-size: 1.1em;
            margin: 10px 0;
        }

        /* Button */
        input[type='submit'] {
            font-size: 1.2em;
            font-weight: 600;
            color: white;
            background-color: #3498db;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            transition: background-color 0.3s ease;
        }

        input[type='submit']:hover {
            background-color: #2980b9;
        }

        /* Form and table styling */
        form, table {
            margin: 20px auto;
            width: 80%;
            max-width: 800px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        table, th, td {
            border: 1px solid #ccc;
        }

        th, td {
            padding: 10px;
            text-align: center;
        }

        footer {
            margin-top: 40px;
            font-size: 0.9em;
            color: #7f8c8d;
        }
        </style>
    </head>
    <body>
        <h1>Welcome to the Weather Guessing Game!</h1>
        <p>Guess the current temperature in <b>$city</b>.</p>

        <form action='/cgi-bin/Weathergame.sh' method='post'>
            <label for='username'>Enter Your Name:</label>
            <input type='text' id='username' name='username' required><br><br>
            
            <label for='guess'>Your Guess (°C):</label>
            <input type='number' id='guess' name='guess' step='any' required><br><br>

            <input type='hidden' name='city' value='$city'>
            <input type='submit' value='Submit Guess'>
        </form>
    </body>
    </html>"
}

# Handle the case where no guess is provided (i.e., when the form is first loaded)
if [ -z "$guess" ]; then
    render_form
    exit 0
fi

# Validate the guess input
if [[ "$guess" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
    # Load city data
    load_cities

    # Check if the city exists in the data
    if [[ -z "${cities[$selected_city]}" ]]; then
        echo "<h1>Error</h1><p>Invalid city selected.</p>"
        exit 1
    fi

    # Get latitude and longitude for the selected city
    read lat lon <<<"${cities[$selected_city]}"

    # Fetch the actual temperature for the selected city
    actual_temp=$(get_temperature "$lat" "$lon")

    # Check if we successfully got the temperature
    if [ -z "$actual_temp" ]; then
        echo "<h1>Error</h1><p>Unable to fetch temperature data. Please try again later.</p>"
        exit 1
    fi

    # Calculate the difference between the guess and actual temperature
    difference=$(echo "$actual_temp - $guess" | bc)
    abs_diff=$(echo "$difference" | awk '{print ($1 < 0) ? -$1 : $1}')

    # Save the result to the leaderboard
    echo "$username,$selected_city,$guess,$actual_temp,$abs_diff" >> "$LEADERBOARD_FILE"

    # Display the result of the game
    if (( $(echo "$abs_diff <= 3" | bc -l) )); then
        echo "<h1>Correct!</h1><p>The actual temperature in $selected_city was $actual_temp°C.</p>"
    else
        echo "<h1>Wrong Guess!</h1><p>Your guess was off by $abs_diff°C. The correct temperature was $actual_temp°C in $selected_city.</p>"
    fi

    # Display the leaderboard, sorted by the closest guesses
    display_leaderboard

    # Replay and Exit buttons
    echo "
    <form action='/cgi-bin/Weathergame.sh' method='post'>
        <input type='submit' value='Replay'>
    </form>

    <form action='/index.html' method='get'>
        <input type='submit' value='Exit'>
    </form>"

else
    # If the guess is invalid
    echo "<h1>Invalid Input</h1><p>Please enter a valid number for your guess.</p>"
fi
