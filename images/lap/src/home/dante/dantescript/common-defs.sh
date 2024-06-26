#!/bin/bash

# Common environment variables and definitions for all dantescript scripts

##
## Configurables
##
export PARSIFAL_BRANCH="dante"


##
## Conventions we use
##

# mountpoint for the volume
export MOUNT=/var/www/html/

# point in ${MOUNT} where the dante wiki attaches
export TARGET=wiki-dir

# directory where to pick up the minimal initial contents
export CONT=/home/dante/initial-contents/generic 

##
## codes for printf
##
export RESET="\e[0m"
export ERROR="\e[1;31m"
export GREEN="\e[1;32m"
