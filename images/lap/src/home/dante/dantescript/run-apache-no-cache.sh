#!/bin/bash

RESET="\e[0m"
ERROR="\e[1;31m"
GREEN="\e[32m"

printf "*** THIS IS run-apache-no-cache.sh\n\n"

printf "*** run-apache-no-cache.sh: Starting apache..."
  service php8.2-fpm start
  exec 1>&1 2>&2
  apachectl -D DUMP_INCLUDES 
  exec 1>&1 2>&2
  apachectl -D DUMP_MODULES 
  exec 1>&1 2>&2
  apachectl  -D NO_CACHE start
  exec 1>&1 2>&2
printf "DONE with starting apache"

printf "*** EXITING run-apache-no-cache.sh"