#!/bin/sh

# entrypoint of lap

# call the specific entrypoint of ssh docker if it exists (used when we are built using ssh in the chain)

if [ -f "/ssh-entry.sh" ]; then
  echo "** Found ssh-entry and running it"
  source /ssh-entry.sh
else
  echo "** Just as information: COULD NOT FIND /ssh-entry.sh"
fi


if [ -f "/apache-php-fpm-entry.sh" ]; then
  echo "** Found apache-php-fpm-entry.sh and running it"
  source /apache-php-fpm-entry.sh
else
  echo "** COULD NOT FIND /apache-php-fpm-entry.sh"
fi

echo "Sleeping for infinity to keep docker container alive..."
sleep infinity
echo "Finished sleeping. This should not happen"














