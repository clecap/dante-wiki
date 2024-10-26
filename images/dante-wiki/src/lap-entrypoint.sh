#!/bin/bash

# entrypoint of image lap
# Takes as parameter a list of scripts residing in /home/dante/dantescript

source /home/dante/dantescript/common-defs.sh

## Say hello
printf "\n*** *** This is /lap-entrypoint.sh V2 *** ***\n"

loadSecrets

## Iterate over each argument in the list of arguments we are called on
printf "$GREEN*** /lap-entrypoint.sh: Iterating the $# arguments: $* ${RESET}\n"
for script in "$@"; do
  if [ -f "/home/dante/dantescript/$script" ]; then
      printf "\n$GREEN***/lap-entrypoint.sh: Executing dantescript: /home/dante/dantescript/$script ---------- $script $RESET\n"
      RETURN_VALUE="returnvalue-initialized" ; 
      source "/home/dante/dantescript/$script" 
      EXIT_STATUS=$?
#      printf "\n$GREEN***/lap-entrypoint.sh: Now testing on exit status\n"
      if [[ $EXIT_STATUS -ne 0 ]]; then
        exec 1>&1 2>&2 ; echo "$script exited with status $EXIT_STATUS"
      else
        exec 1>&1 2>&2 ; echo "$script returned with status $EXIT_STATUS"
      fi
      if [ "$RETURN_VALUE" == "shutdown" ]; then
          printf "\n/lap-entrypoint.sh: $script returned $RETURN_VALUE, shutting down now\n" ; exit 0
        else
           printf "\n/lap-entrypoint.sh: $script returned $RETURN_VALUE, moving on\n"
      fi
    else
      printf "\n${ERROR}/lap-entrypoint.sh: Error: File '$script' not found or is not a regular file. $RESET\n"
    fi
done

printf "\n\n/lap-entrypoint.sh: Completed all commands. To keep container alive I will now sleep\n\n"

sleep infinity