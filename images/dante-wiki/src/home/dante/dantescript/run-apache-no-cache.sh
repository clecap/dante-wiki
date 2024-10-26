#!/bin/bash

source /home/dante/dantescript/common-defs.sh

printf "*** THIS IS run-apache-no-cache.sh\n\n"
 
printf "*** run-apache-no-cache.sh: Starting fpm...\n"
  sudo service php8.2-fpm start 
  exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache-no-cache.sh: Listing apache includes...\n"
  sudo apachectl -D DUMP_INCLUDES 
  exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache-no-cache.sh: Listing apache modules...\n"
  sudo apachectl -D DUMP_MODULES 
  exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache-no-cache.sh: Testing configuration...\n"
  apachectl configtest
printf "DONE\n"

printf "\n*** Listing active traps: \n"
trap
printf "DONE\n"

# for some unclear reason the below thing does not properly return to the calling shell lap-entrypoint.sh
# in case (1) and error occurs and (2) the final & is missing
# In this scenario the thing crashes locally, does not return to lap-entrypoint.sh and does not give us an
# opportunity to exec into the then stopped container

printf "\n*** run-apache-no-cache.sh: Starting apache NO-CACHE ...\n"
  sudo apachectl  -D NO_CACHE -k start &
printf "DONE with starting apache\n"

printf "${GREEN}*** EXITING run-apache-no-cache.sh\n\n"