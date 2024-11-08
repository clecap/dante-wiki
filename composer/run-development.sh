#!/bin/bash

# runs existing containers after a docker stop or restart


#### TODO: not yet tested or completed !!




export DANTE_IMAGE=dante-wiki:latest
# configures the specific docker image we will use

### TODO: put this as variable into the yaml file  


# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

source $DIR/library.sh

set -e
trap 'abort' ERR

source ${TOP_DIR}/private/configuration.sh

getImageInfo ${DANTE_IMAGE}


# TODO: would be nice if we could include the build process into the YAML file as well.
build

# TODO: research if we can also do this with -d for detached mode and make better use of the health check dependency in the yaml file
#  docker compose -f $TOP_DIR/composer/docker-compose-development.yaml up -d

upServices $TOP_DIR/composer/docker-compose-development.yaml database webserver-after-copy phpmyadmin

waitForContainerRunning dante-wiki-container
# waitForContainerHealthy dante-wiki-container
waitForWebserverServicing
openChrome