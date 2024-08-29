#!/bin/bash

source /home/dante/dantescript/common-defs.sh

printf "*** THIS IS run-apache.sh\n\n"

trap 'abort' ERR

printf "*** run-apache.sh: Starting fpm...\n"
  sudo service php8.2-fpm start
  exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache.sh: Listing apache includes...\n"
  sudo apachectl -D DUMP_INCLUDES
  exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache.sh: Listing apache modules...\n"
  sudo apachectl -D DUMP_MODULES
  exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache.sh: Starting apache with DO-CACHE ...\n"
  sudo apachectl  -D DO_CACHE -k start 
  exec 1>&1 2>&2
printf "DONE with starting apache\n"

trap - ERR

printf "${GREEN}*** EXITING run-apache.sh\n\n"