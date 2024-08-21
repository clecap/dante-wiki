#!/bin/bash

source /home/dante/dantescript/common-defs.sh

printf "*** THIS IS run-apache.sh\n\n"

printf "*** run-apache.sh: Starting fpm...\n"
  service php8.2-fpm start ; exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache.sh: Listing apache includes...\n"
  apachectl -D DUMP_INCLUDES ; exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache.sh: Listing apache modules...\n"
  apachectl -D DUMP_MODULES ; exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache.sh: Starting apache with DO-CACHE ...\n"
  apachectl  -D DO_CACHE -k start ; exec 1>&1 2>&2
printf "DONE with starting apache\n"

printf "${GREEN}*** EXITING run-apache.sh\n\n"