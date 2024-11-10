#!/bin/bash

source /home/dante/dantescript/common-defs.sh

printf "*** THIS IS run-apache.sh\n\n"  

loadSecrets
export APACHE_SERVER_NAME=${MY_DOMAINNAME}

printf "*** run-apache.sh: Generating environment variable file for Apache..."
  sudo rm -f /etc/apache2/env-dante
  sudo rm -f /tmp/env-dante

  # the following variables are used inApache  site configuration file  dante-mediawiki.conf or included files
  # use echo for the \n
  echo "export APACHE_SERVER_NAME=\"${APACHE_SERVER_NAME}\"" >> /tmp/env-dante
  # used in additional-user.conf:
  echo "export APACHE_USE_PASSWORD=\"${APACHE_USE_PASSWORD}\"" >> /tmp/env-dante
  echo "export APACHE_AUTH_NAME=\"${APACHE_AUTH_NAME}\"" >> /tmp/env-dante
  echo "export APACHE_AUTH_USER=\"${APACHE_AUTH_USER}\"" >> /tmp/env-dante
  echo "export APACHE_SERVER_ADMINISTRATOR=\"${APACHE_SERVER_ADMINISTRATOR}\"" >> /tmp/env-dante

  echo "export USING_LDAP=\"${USING_LDAP}\"" >> /tmp/env-dante

  echo "export AuthLDAPURL=\"${AuthLDAPURL}\"" >> /tmp/env-dante
  echo "export AuthLDAPBindDN=\"${AuthLDAPBindDN}\"" >> /tmp/env-dante
  echo "export AuthLDAPBindPassword=\"${AuthLDAPBindPassword}\"" >> /tmp/env-dante
  echo "export LDAP_AUTHNAME=\"${LDAP_AUTHNAME}\"" >> /tmp/env-dante

  sudo mv /tmp/env-dante /etc/apache2/env-dante
  sudo chmod 755 /etc/apache2/env-dante
  sudo chown root:root /etc/apache2/env-dante
printf "DONE generating environment variable file for Apache\n"

exec 1>&1 2>&2

trap 'warn' ERR

### Set Apache caching behaviour
sudo a2disconf cache.conf
sudo a2enconf no-cache.conf
sudo a2ensite dante-mediawiki.conf

### Enable LDAP
if [ "$USING_LDAP" = "true" ]; then
  printf "   Enabling LDAP..."
  sudo a2enconf ldap-restrictions.conf
  printf "DONE (enabling ldap)\n"
else
  printf "   DISABLEING LDAP..."
  sudo a2disconf ldap-restrictions.conf
  echo "DONE (disabling ldap)\n"
fi

### Enable PASSWORDS
if [ "$APACHE_USE_PASSWORD" = "true" ]; then
  printf "   Enabling Passwords..."
  sudo a2enconf user-restrictions.conf
  printf "DONE (enabling passwords)\n"
else
  printf "   DISABLEING Passwords..."
  sudo a2disconf user-restrictions.conf
  echo "DONE (disabling passwords)\n"
fi

# Disable all superfluous configurations
sudo a2disconf charset.conf
sudo a2disconf localized-error-pages.conf
sudo a2disconf security.conf
sudo a2disconf serve-cgi-bin.conf



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

printf "\n*** run-apache.sh: Testing configuration...\n"
  apachectl configtest
  exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** run-apache.sh: Listing active traps: \n"
trap
printf "DONE\n"

loadSecrets

printf "\n*** run-apache.sh: Starting apache...\n"
  sudo apachectl -k start & sleep infinity
printf "DONE with starting apache\n"

trap - ERR

printf "${GREEN}*** EXITING run-apache.sh ${RESET}\n\n"