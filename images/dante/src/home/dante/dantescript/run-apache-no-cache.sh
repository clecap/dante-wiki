#!/bin/bash

source /home/dante/dantescript/common-defs.sh

printf "*** THIS IS run-apache-no-cache.sh\n\n"

printf "*** run-apache-no-cache.sh: Starting fpm...\n"
  service php8.2-fpm start ; exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache-no-cache.sh: Listing apache includes...\n"
  apachectl -D DUMP_INCLUDES ; exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache-no-cache.sh: Listing apache modules...\n"
  apachectl -D DUMP_MODULES ; exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache-no-cache.sh: Starting apache NO-CACHE ...\n"
  apachectl  -D NO_CACHE -k start ; exec 1>&1 2>&2
printf "DONE with starting apache\n"

printf "${GREEN}*** EXITING run-apache-no-cache.sh\n\n"