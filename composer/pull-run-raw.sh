#!/bin/bash

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

# read in the library file for our shell
source $DIR/library.sh || { echo "ERROR: could not source $DIR/library.sh"; exit 1; }

set -e
trap 'abort' ERR



D_REGISTRY="docker.io"   # at which registry    "docker.io"  or  "" for local only    
D_OWNER="clecap"         # owner / root namespace of repository
D_REPO="dante-wiki"      # sepcific repository name
D_TAG="latest"           # tag to be used for fetch

# determine the full specification
D_SPEC="${D_REGISTRY}/${D_OWNER}/${D_REPO}:${D_TAG}"


start "Doing a docker pull ${D_SPEC}"
  docker pull "${D_SPEC}"
ok "Pulled"


getImageInfo "${D_SPEC}"


askConfirmation

pullBySpec


# shutdown all running services of this kind after displaying a confirmation (to ensure git has been pushed)
## probably no confirmation since this is for remote - or is it not ??? TODO

downAllServices $TOP_DIR/composer/docker-compose-development.yaml

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