#!/bin/bash

echo "*** THIS IS run-apache.sh"

echo "** Starting apache..."
  service php8.2-fpm start
  apachectl start
echo "DONE with starting apache"

echo "*** EXITING run-apache.sh"