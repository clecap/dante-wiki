#!/bin/bash

# entrypoint of lap

# possible commands are:
#
# run-ssh
# run-apache
# run-apache-fpm
# sleep

echo "*** This is /lap-entrypoint.sh"


echo "*** /lap-entrypoint.sh sees the following secret files:"
ls -alg /run/secrets
echo ""
if [ -f "/run/secrets/configuration" ]; then
    echo "*** /lap-entrypoint.sh will now load configuration"
    source /run/secrets/configuration
    echo "*** /lap-entrypoint.sh did load configuration"
  else
    echo "*** /lap-entrypoint.sh could not find configuration file, EXITING "
    exit 1
fi





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

