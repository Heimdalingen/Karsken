<?php
// Database information, so it connects with the database
$host = 'localhost';  // MariaDB host 
$username = 'jesper';   // database username
$password = 'jesper';       // database password
$dbname = 'logininfo';  // The database name

// Creates a connection to MariaDB
$conn = new mysqli($host, $username, $password, $dbname);

// Checks the connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error); // if it fails, error will show
}

// Checks if the form is submitted
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $username = $_POST['username'];  // Get the username from the form
    $password = $_POST['password'];  // Get the password from the form
    $temperature = $_POST['temperature'];  // Get the temperature preference

    // makes the password unreadable in the database, security measures
    $hashed_password = password_hash($password, PASSWORD_DEFAULT);

    // Insert the form data into the database using a prepared statement
    $send = $conn->prepare("INSERT INTO users (username, password, temperature) VALUES (?, ?, ?)");
    $send->bind_param("sss", $username, $hashed_password, $temperature);

    // Executes the prepared statement
    if ($send->execute()) {
        echo "New record created successfully. Preferred Temperature Unit: $temperature"; // is this needed?
        
        // Set cookie with user info in header, dosnt work
        setcookie("user", $username, "/");

        // Redirect to another page, sends to the game
        header("Location: videre.html"); // directs to game, change file
        exit;
    } else {
        echo "Error: " . $send->error; // error message if it doesnt send
    }

    // Close the prepared statement
    $send->close();
}

// Close the database connection
$conn->close();
?>
