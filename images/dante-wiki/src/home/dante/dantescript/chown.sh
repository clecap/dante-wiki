#!/bin/bash

source /home/dante/dantescript/common-defs.sh

stdbuf -o0 -e0  printf "*** THIS IS chown.sh\n\n"

# an error in the chown might happen in the git directory on restart
# in THIS case a wrong permission (in git) is not missing critical
# thus we disable the stop on error and trap options which we might have inherited from earlier or caller

trap warn ERR


stdbuf -o0 -e0  printf "\n*** chown.sh: chown all files to www-data...\n"

#  printf "\n chown timing for one\n"
#  time find ${MOUNT}/${TARGET} -not -path "*/.git/*" -exec chown www-data:www-data {} \;
## took 2 minutes 11 seconds real time
#  printf "\n DONE ONE\n"

#  sleep 10

#  printf "\n chown tming for parallel\n"
#  time ( find ${MOUNT}/${TARGET} -not -path "*/.git/*" -print0 | xargs -0 -P 8 -n 10 chown www-data:www-data )
## Does this in parallel, speeding up the entire process
## Took 0 minutes 14 seconds real time (scheduled immediately afterwards, together - cache effect ?
#  printf "\nDONE PARALLEL\n"



stdbuf -o0 -e0   printf "\n chown tming for parallel\n"
  time ( find ${MOUNT}/${TARGET} -not -path "*/.git/*" -print0 | xargs -0 -P 16 -n 20 chown www-data:www-data )
# Does this in parallel, speeding up the entire process
# Took 14 seconds real time with 16 procs 10 n
# 
stdbuf -o0 -e0   printf "\nDONE PARALLEL\n"



#  chown -R www-data:www-data ${MOUNT}/${TARGET} ; exec 1>&1 2>&2
stdbuf -o0 -e0 printf "DONE chowning all files\n"

trap abort ERR

stdbuf -o0 -e0  printf "${GREEN}*** EXITING chown.sh\n\n"