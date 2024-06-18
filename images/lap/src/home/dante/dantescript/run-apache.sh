#!/bin/bash

echo "*** THIS IS run-apache.sh"

echo "** Starting apache..."
  MODE=PHP
  export MODE
    apachectl start
echo "DONE with starting apache"

echo "*** EXITING run-apache.sh"