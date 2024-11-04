#!/bin/bash

source /home/dante/dantescript/common-defs.sh

printf "*** THIS IS run-apache-no-cache.sh\n\n"  

loadSecrets
export APACHE_SERVER_NAME=${MY_DOMAINNAME}

printf "*** run-apache-no-cache.sh: Generating environment variable file for Apache..."
  rm -f /etc/apache2/env-dante
  rm -f /tmp/env-dante
  # used in site configuration file  dante-mediawiki.conf:
  printf "export APACHE_SERVER_NAME=\"${APACHE_SERVER_NAME}\"" >> /tmp/env-dante
  # used in additional-user.conf:
  printf "export APACHE_USE_PASSWORD=\"${APACHE_USE_PASSWORD}\"" >> /tmp/env-dante
  printf "export APACHE_AUTH_NAME=\"${APACHE_AUTH_NAME}\"" >> /tmp/env-dante
  printf "export APACHE_AUTH_USER=\"${APACHE_AUTH_USER}\"" >> /tmp/env-dante
  
  sudo mv /tmp/env-dante /etc/apache2/env-dante
  sudo chmod 755 /etc/apache2/env-dante
  sudo chown www-data:www-data /etc/apache2/env-dante
printf "DONE generating environment variable file for Apache\n"

exec 1>&1 2>&2

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
  exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache-no-cache.sh: Listing active traps: \n"
trap
printf "DONE\n"

loadSecrets

printf "\n*** run-apache-no-cache.sh: Starting apache NO-CACHE ...\n"
  sudo apachectl -D NO_CACHE -k start
printf "DONE with starting apache\n"

printf "${GREEN}*** EXITING run-apache-no-cache.sh\n\n"