#!/bin/bash

source /home/dante/dantescript/common-defs.sh

printf "*** THIS IS run-apache-no-cache.sh\n\n"

# an error in the chown might happen in the git directory on restart
# in THIS case a wrong permission (in git) is not missiogn critical
# thus we disable the stop on error option which we might have inherited from earlier or caller
set +e

printf "\n*** run-apache-no-cache.sh: chown all files to www-data...\n"
  chown -R www-data:www-data ${MOUNT}/${TARGET} ; exec 1>&1 2>&2
printf "DONE chowning all files\n"

set -e

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