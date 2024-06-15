#!/bin/bash

# entrypoint of lap

# possible commands are:
#
# run-ssh
# run-apache
# run-apache-fpm
# sleep

echo "/lap-entrypoint.sh: I was started"

chmod 400 /etc/ssl/apache2/server.key
chmod 444 /etc/ssl/apache2/server.pem

crond
echo "/lap-entrypoint.sh: Started crond"

echo "/lap-entrypoint.sh: Now iterating ( $@ )"
# Iterate over each argument in the list of arguments we are called on
for script in "$@"; do
    # Check if the file exists and is a regular file
    echo "/lap-entrypoint.sh: Checking file $script"
    if [ -f "/dantescript/$script" ]; then
        echo "/lap-entrypoint.sh: Executing dantescript: /dantescript/$script"
        /bin/bash "/dantescript/$script"
    else
        echo "/lap-entrypoint.sh: Error: File '$script' not found or is not a regular file."
    fi
done

echo "/lap-entrypoint.sh: Completed loop - which should not have been - to keep container alive I will now sleep"

sleep infinity

