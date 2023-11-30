#!/bin/bash

# entrypoint of lap

# possible commands are:
#
# run-ssh
# run-apache
# run-apache-fpm
# sleep

chmod 400 /etc/ssl/apache2/server.key
chmod 444 /etc/ssl/apache2/server.pem

# Iterate over each argument
for script in "$@"; do
    # Check if the file exists and is a regular file
    if [ -f "$script" ]; then
        echo "Executing dantescript: /dantescript/$script.sh"
        /bin/bash "/dantescript/$script.sh"
    else
        echo "Error: File '$script' not found or is not a regular file."
    fi
done