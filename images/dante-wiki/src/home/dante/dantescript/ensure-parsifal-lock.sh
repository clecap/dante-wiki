#!/bin/bash

source /home/dante/dantescript/common-defs.sh

# we must ensure that for parsifal there is a reasonable lock directory
# independently how the rest of the file system was generated
# and this must not be on a mounted file system, as there the lock mechanisms do not work

printf "*** THIS IS ensure-parsifal-lock.sh\n"
  stdbuf -o0 -e0  mkdir -p /var/lock/parsifal
  stdbuf -o0 -e0  chown -R www-data:www-data /var/lock/parsifal
printf "*** EXITING chown.sh\n\n"