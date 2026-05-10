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

DH_PULL_SPEC="clecap/dante-wiki@sha256:c48e8f5fb8d56b8b4870904cd78600f45130aaee7f30c58944185fffb517f158"

pullBySpec


mkdir -p private && chmod 755 private

export CONFIG_ENCRYPTED_URL="https://iuk.one/configuration-iuk-stage.sh.enc"
read -s -p "Password: " CONFIG_DECRYPTION_KEY && export CONFIG_DECRYPTION_KEY

printf "\n **** compos configure\n"

docker compose -f "$TOP_DIR/composer/docker-compose-development.yaml" run --rm get-configuration

printf "\n **** compos configure DONE \n"

# read in the active configuration
source ${TOP_DIR}/private/configuration.sh

# TODO: research if we can also do this with -d for detached mode and make better use of the health check dependency in the yaml file
#  docker compose -f $TOP_DIR/composer/docker-compose-development.yaml up -d

upServices $TOP_DIR/composer/docker-compose-development.yaml database webserver-raw-https phpmyadmin

waitForWebserverServicing
openChrome