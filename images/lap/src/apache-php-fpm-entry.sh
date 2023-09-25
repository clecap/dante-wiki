#!/bin/sh


##
## Task to be done for both scenarios
##
common ()
{

# fix some permissions
  chmod 400 /etc/ssl/apache2/server.key
  chmod 444 /etc/ssl/apache2/server.pem

  if [ -f "/mediawiki-alpine-lamp-php.ini" ]; then
    echo "** Found /mediawiki-alpine-lamp-php.ini override file and copying it in"
    cat /mediawiki-alpine-lamp-php.ini >> /etc/php7/php.ini
    rm -f /mediawiki-alpine-lamp-php.ini
  else
    echo "** COULD NOT FIND /mediawiki-alpine-lamp-php.ini"
  fi




# fix some ownership 
#  chown apache:apache /var/log/apache2
#  chown apache:apache /var/www/localhost/htdocs
#  mkdir /run/apache2
#  chown apache:apache /run/apache2
}


startFpm () 
{
  echo -n "** Starting fpm in background..."
  /usr/sbin/php-fpm7 --php-ini /etc/php7/php.ini
  echo "DONE with starting fpm in the background"; echo ""
}


startApache () 
{
  echo -n "** Starting apache..."
  /usr/sbin/httpd
  echo "DONE with starting apache"; echo ""
}


common

if [ "$MODE" = "PHP" ]; then
  echo ""; echo "** Detected PHP mode"; echo ""
  startApache
elif [ "$MODE" = "FPM" ]; then
  echo ""; echo "** Detected FPM mode"; echo ""
  startFpm
  startApache
else
  echo ""; echo "** ERROR: Envrionment variable MODE must be set to either PHP or FPM"; echo "";
fi

echo "** Starting to sleep"
sleep infinity