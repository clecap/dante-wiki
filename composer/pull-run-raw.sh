#!/bin/bash

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

# read in the library file for our shell
source $DIR/library.sh

set -e
trap 'abort' ERR



# getImageInfo ${DANTE_IMAGE}

# shutdown all running services of this kind after displaying a confirmation (to ensure git has been pushed)
## probably no confirmation since this is for remote - or is it not ??? TODO
askConfirmation
downAllServices $TOP_DIR/composer/docker-compose-development.yaml

pullBySpec

mkdir -p private && chmod 755 private


export CONFIG_ENCRYPTED_URL="https://iuk.one/configuration-iuk-stage.sh.enc"
read -s -p "Password: " CONFIG_DECRYPTION_KEY && export CONFIG_DECRYPTION_KEY

docker compose -f composer/docker-compose-development.yaml run --rm get-configuration


# read in the active configuration
source ${TOP_DIR}/private/configuration.sh


# TODO: research if we can also do this with -d for detached mode and make better use of the health check dependency in the yaml file
#  docker compose -f $TOP_DIR/composer/docker-compose-development.yaml up -d

upServices $TOP_DIR/composer/docker-compose-development.yaml database webserver-raw-https phpmyadmin

waitForWebserverServicing
openChrome