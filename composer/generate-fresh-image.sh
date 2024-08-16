#!/bin/bash

SERVICE_CONTAINER=dante-wiki-container

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

RESET="\e[0m"; ERROR="\e[1;31m"
# 32m for green
# 92m for bold green
GREEN="\e[1;92m"

set -e

### set terminate on error 
abort() 
{
  printf "%b" "\n\n\e[1;31m *** *** *** ABORTED *** *** *** \e[0m"; exit 1 
}

trap 'abort' ERR



printf "\n$GREEN---Building image dante-wiki if necessary...$RESET\n" ; 
  docker build -t dante-wiki:latest $TOP_DIR/images/dante-wiki/src
printf "$GREEN---DONE$RESET\n"
