#!/bin/bash

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

# read in the library file for our shell
source $DIR/library.sh

set -e
trap 'abort' ERR

# read in the active configuration
source ${TOP_DIR}/private/configuration.sh

# getImageInfo ${DANTE_IMAGE}

##
## PHASE 1: all user interaction - the user answers all questions first, then the script runs unattended
##

# show what is running and ask for confirmation before taking it down (to ensure git has been pushed)
listServices
askConfirmation "Did you *** SAVE *** the  (1) GIT files and (2) the SYSTEM files and (3) the USER content - we will now down all services an status will no longer be recoverable !!"

# ask whether to use the docker build cache or to build from scratch; no default, anything else aborts
printf "%b" "\n${ERROR}Build docker image using the cache or build from scratch [c]ache / [s]cratch ? ${RESET}"
read -r reply
if [[ "$reply" =~ ^[Cc]$ ]]; then
  BUILD_MODE=cache
elif [[ "$reply" =~ ^[Ss]$ ]]; then
  BUILD_MODE=scratch
else
  abort
fi

##
## PHASE 2: unattended execution
##

# shutdown all running services of this kind
downAllServices $TOP_DIR/compose/docker-compose-development.yaml

if [ "$BUILD_MODE" = "cache" ]; then
  build
else
  buildNoCache
fi

# TODO: research if we can also do this with -d for detached mode and make better use of the health check dependency in the yaml file
#  docker compose -f $TOP_DIR/composer/docker-compose-development.yaml up -d

upServices $TOP_DIR/compose/docker-compose-development.yaml database webserver-raw-https phpmyadmin

waitForWebserverServicing
openChrome