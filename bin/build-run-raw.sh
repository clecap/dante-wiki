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

# name of the docker volume holding the database of service database
DB_VOLUME_NAME=dante-db-raw

# compose substitutes ${DANTE_DB_VOLUME} in docker-compose-development.yaml, so it must be exported
export DANTE_DB_VOLUME=${DB_VOLUME_NAME}


# getImageInfo ${DANTE_IMAGE}

##
## PHASE 1: all user interaction - the user answers all questions first, then the script runs unattended
##

CURRENT_DANTE_BRANCH="$(git branch --show-current)"   

printf "\n"
showCurrentBranch

# show what is running and ask for confirmation before taking it down (to ensure git has been pushed)
listServices
CONFIRMED=$(askChoice "Did you *** SAVE *** the  (1) GIT files and (2) the SYSTEM files and (3) the USER content [y/N]" y yes)

# ask whether to use the docker build cache or to build from scratch; no default, anything else aborts
BUILD_MODE=$(askChoice "Build docker image using the cache or build from scratch [c]ache / [s]cratch ?" c cache s scratch)


# ask whether to keep or remove an existing database volume; no default, anything else aborts
REMOVE_DB_VOLUME=no
if docker volume inspect "$DB_VOLUME_NAME" > /dev/null 2>&1; then
  listVolumes
  REMOVE_DB_VOLUME=$(askChoice "Database volume ${DB_VOLUME_NAME} exists. [k]eep its contents / [r]emove it and start with an empty database ?" k no r yes)
fi

##
## PHASE 2: unattended execution
##

# shutdown all running services of this kind
downAllServices $TOP_DIR/compose/docker-compose-development.yaml

# remove the database volume only after the down, since a volume in use by a container cannot be removed
if [ "$REMOVE_DB_VOLUME" = "yes" ]; then
  printf "\n${GREEN}---Removing database volume ${DB_VOLUME_NAME}...${RESET}\n"
  docker volume rm "$DB_VOLUME_NAME"
  printf "${GREEN}---DONE${RESET}\n"
fi

if [ "$BUILD_MODE" = "cache" ]; then
  build "$CURRENT_DANTE_BRANCH"
else
  buildNoCache "$CURRENT_DANTE_BRANCH"
fi

# TODO: research if we can also do this with -d for detached mode and make better use of the health check dependency in the yaml file
#  docker compose -f $TOP_DIR/composer/docker-compose-development.yaml up -d

upServices $TOP_DIR/compose/docker-compose-development.yaml database webserver-raw-https phpmyadmin

waitForWebserverServicing
openChrome