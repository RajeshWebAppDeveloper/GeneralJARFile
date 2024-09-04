#!/bin/bash

# Define variables
JAR_FILE="RentARide_4_sep_2024.jar"
LOG_FILE="RentARide_4_sep_2024.log"

# Run the JAR file in the background and redirect stdout and stderr to the log file
nohup java -jar $JAR_FILE > $LOG_FILE 2>&1 &

# Get the process ID of the last background command
PID=$!

# Print the process ID to the console
echo "Application started with PID: $PID"
echo "Logs are being written to $LOG_FILE"

# Exit the script to return control to the terminal
exit 0

