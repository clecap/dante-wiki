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

getImageInfo ${DANTE_IMAGE}

# shutdown all running services of this kind
askConfirmation
downAllServices $TOP_DIR/composer/docker-compose-development.yaml

# TODO: would be nice if we could include the build process into the YAML file as well.
build

# TODO: research if we can also do this with -d for detached mode and make better use of the health check dependency in the yaml file
#  docker compose -f $TOP_DIR/composer/docker-compose-development.yaml up -d

upServices $TOP_DIR/composer/docker-compose-development.yaml database webserver-raw-https phpmyadmin

waitForWebserverServicing
openChrome