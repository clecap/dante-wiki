#!/bin/bash

source /home/dante/dantescript/common-defs.sh

stdbuf -o0 -e0  printf "*** THIS IS chown.sh\n"

# an error in the chown might happen in the git directory on restart
# in THIS case a wrong permission (in git) is not missing critical
# thus we disable the stop on error and trap options which we might have inherited from earlier or caller
trap warn ERR

stdbuf -o0 -e0  printf "*** chown.sh: chown all files to www-data...\n"

# do not change permissions inside git to the extent possible

#  stdbuf -o0 -e0  printf "\n chown timing for one\n"
#  find ${MOUNT}/${TARGET} -not -path "*/.git/*" -exec chown www-data:www-data {} \;
## took 2 minutes 11 seconds real time
#  stdbuf -o0 -e0   printf "\n DONE ONE\n"

  find ${MOUNT}/${TARGET} -not -path "*/.git/*" -print0 | xargs -0 -P 16 -n 20 chown www-data:www-data 
# Does this in parallel, speeding up the entire process
# Took 14 seconds real time with 16 procs 10 n

stdbuf -o0 -e0 printf "DONE chowning all files\n"

trap errorTrap ERR

stdbuf -o0 -e0  printf "*** EXITING chown.sh\n\n"