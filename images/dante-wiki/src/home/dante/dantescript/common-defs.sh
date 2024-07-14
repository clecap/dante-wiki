#!/bin/bash

# Common environment variables and definitions for all dantescript scripts

##
## Configurables
##
export PARSIFAL_BRANCH="dante"

# the name of the branch to which we will clone
DANTE_BRANCH=master

# the remote repository for dante-delta
REMOTE_REPO_DANTE=https://github.com/clecap/dante-delta.git


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

# 32m for green
# 92m for bold green
export GREEN="\e[1;92m"

  

### set terminate on error 
abort() 
{ 
  printf "%b" "\n\n\e[1;31m *** *** *** ****** *** *** *** \e[0m\n"; 
  printf "%b" "\e[1;31m *** *** *** ERROR *** *** *** \e[0m\n"; 
  printf "%b" "\e[1;31m *** *** *** ****** *** *** *** \e[0m\n";

  printf "\n\n*** Sleeping for 1 hour to keep container running for debug attempts ***\n\n"
  sleep 3600

}

