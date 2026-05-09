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

# shutdown all running services of this kind after displaying a confirmation (to ensure git has been pushed)
askConfirmation
downAllServices $TOP_DIR/composer/docker-compose-development.yaml

pullBySpec


export CONFIG_ENCRYPTED_URL="https://iuk.one/configuration-iuk-stage.sh.enc"
read -s -p "Password: " CONFIG_DECRYPTION_KEY && export CONFIG_DECRYPTION_KEY

docker compose -f composer/docker-compose-development.yaml run --rm get-configuration


# TODO: research if we can also do this with -d for detached mode and make better use of the health check dependency in the yaml file
#  docker compose -f $TOP_DIR/composer/docker-compose-development.yaml up -d

upServices $TOP_DIR/composer/docker-compose-development.yaml database webserver-raw-https phpmyadmin

waitForWebserverServicing
openChrome