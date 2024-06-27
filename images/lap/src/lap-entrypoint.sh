#!/bin/bash

# entrypoint of image lap
# Takes as parameter a list of scripts residing in /home/dante/dantescript

source /home/dante/dantescript/common-defs.sh

## Say hello
printf "\n *** *** This is /lap-entrypoint.sh\n"

## Load the secret configuration file
if [ -f "/run/secrets/configuration" ]; then
    printf "$GREEN*** /lap-entrypoint.sh will now load configuration... "
    source /run/secrets/configuration ; exec 1>&1 2>&2
    printf "DONE loading configuration\n"
  else
    printf "$ERROR*** /lap-entrypoint.sh could not find configuration file, EXITING $RESET\n"
    exit 1
fi

## Iterate over each argument in the list of arguments we are called on
printf "$GREEN*** /lap-entrypoint.sh: Iterating the $# arguments: $* \n"
for script in "$@"; do
  if [ -f "/home/dante/dantescript/$script" ]; then
      printf "$\nGREEN***/lap-entrypoint.sh: Executing dantescript: /home/dante/dantescript/$script ---------- $script \n"
      RETURN_VALUE="returnvalue-initialized" ; source "/home/dante/dantescript/$script" ; exec 1>&1 2>&2
      if [ "$RETURN_VALUE" == "shutdown" ]; then
          printf "\n/lap-entrypoint.sh: $script returned $RETURN_VALUE, shutting down now\n" ; exit 0
        else
           printf "\n/lap-entrypoint.sh: $script returned $RETURN_VALUE, moving on\n"
      fi
    else
      printf "\n${ERROR}/lap-entrypoint.sh: Error: File '$script' not found or is not a regular file.\n"
    fi
done

printf "\n\n/lap-entrypoint.sh: Completed all commands. To keep container alive I will now sleep\n\n"

sleep infinity