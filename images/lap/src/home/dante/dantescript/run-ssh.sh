#!/bin/sh

# entrypoint of lap

#### deprecated ????

# call the specific entrypoint of ssh docker if it exists (used when we are built using ssh in the chain)

if [ -f "/ssh-entry.sh" ]; then
  echo "** Found ssh-entry and running it"
  source /ssh-entry.sh
else
  echo "** Just as information: COULD NOT FIND /ssh-entry.sh"
fi