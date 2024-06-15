#!/bin/bash

echo "*** THIS IS run-apache-fpm.sh"

echo "** Starting fpm in background..."
  /usr/sbin/php-fpm7 --php-ini /etc/php7/php.ini
echo "DONE with starting fpm in the background"

echo "** Starting apache..."
  MODE=FPM
  export MODE
  /usr/sbin/httpd
echo "DONE with starting apache"

echo "*** EXITING run-apache-fpm.sh"

