#!/bin/bash

echo "*** THIS IS run-apache.sh"

echo "** Starting apache..."
  service php8.2-fpm start
  apachectl start -DNO_CACHE
echo "DONE with starting apache"

echo "*** EXITING run-apache.sh"