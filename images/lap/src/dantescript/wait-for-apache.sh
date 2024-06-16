#!/bin/bash

# BROKEN currently - does not do what we want


# Define the URL to check
URL="http://localhost:8080"

# Function to check if the server is up
is_server_up() {
    curl -s --head "$URL" | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null
}

# Wait until the server is up
echo "wait-for-apache.sh: Waiting for Apache server to be ready..."

until is_server_up; do
    echo -n "."
    sleep 2
done

echo "wait-for-apache.sh: Apache server is up and running!"