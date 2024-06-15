#!/bin/bash

echo "*** THIS IS run-apache.sh"

echo "** Starting apache..."
  MODE=PHP
  export MODE
  /usr/sbin/httpd
echo "DONE with starting apache"

echo "*** EXITING run-apache.sh"