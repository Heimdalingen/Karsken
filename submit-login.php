<?php
// Database connection details for MariaDB
$host = 'localhost';  // MariaDB host, usually localhost
$username = 'jesper';   // Your MariaDB username
$password = 'jesper';       // Your MariaDB password
$dbname = 'login_system';  // The database name

// Create a connection to MariaDB
$conn = new mysqli($host, $username, $password, $dbname);

// Check the connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Check if the form is submitted
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $username = $_POST['username'];  // Get the username from the form
    $password = $_POST['password'];  // Get the password from the form
    $temperature = $_POST['temperature'];  // Get the temperature preference

    // Hash the password for security
    $hashed_password = password_hash($password, PASSWORD_DEFAULT);

    // Insert the form data into the database using a prepared statement
    $stmt = $conn->prepare("INSERT INTO users (username, password, temperature) VALUES (?, ?, ?)");
    $stmt->bind_param("sss", $username, $hashed_password, $temperature);

    // Execute the prepared statement
    if ($stmt->execute()) {
        echo "New record created successfully. Preferred Temperature Unit: $temperature";
        
        // Set cookie with user info in header
        setcookie("user", $username, "/");

        // Redirect to another page
        header("Location: videre.html");
        exit;
    } else {
        echo "Error: " . $stmt->error;
    }

    // Close the prepared statement
    $stmt->close();
}

// Close the database connection
$conn->close();
?>
