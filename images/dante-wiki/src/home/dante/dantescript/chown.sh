#!/bin/bash

source /home/dante/dantescript/common-defs.sh

printf "*** THIS IS chown.sh\n\n"

# an error in the chown might happen in the git directory on restart
# in THIS case a wrong permission (in git) is not missing critical
# thus we disable the stop on error and trap options which we might have inherited from earlier or caller

trap warn ERR


printf "\n*** chown.sh: chown all files to www-data...\n"
  find ${MOUNT}/${TARGET} -not -path "*/.git/*" -exec chown www-data:www-data {} \;
# 
# find dir -not -path "*/git/*" -print0 | xargs -0 -P 8 -n 10 chown www-data:www-data
# Does this in parallel, speeding up the entire process

#  chown -R www-data:www-data ${MOUNT}/${TARGET} ; exec 1>&1 2>&2
printf "DONE chowning all files\n"

trap abort ERR

printf "${GREEN}*** EXITING chown.sh\n\n"