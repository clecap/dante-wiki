#!/bin/bash


##
## FREQUENTLY CHANGED PARAMETERS 
##

VERSION=1.59                   # Version number, just for identification purposes

TAG="latest"

usage()
{
  cat <<EOF
Usage: $(basename $0) <method> <configuration>

  First parameter:  Method how to get the docker image. Choices:
    build           Build locally
    pull-local      Pull from local docker cache
    pull-dh         Pull from docker hub
    pull-gh         Pull from github

  Second parameter: Configuration to be used. Choices:
    iuk-stage       iuk-stage.informatik.uni-rostock.de
    iuk-dante       iuk-dante.informatik.uni-rostock.de
    clemenscap.de
    ki40.iuk.one

  Version of the command: ${VERSION}

EOF
}


##    
## CONFIGURABLE PARAMETERS
##

## LOCAL configuration
MAIN_DIR="."    # Main directory on the machine INTO which we install, relative to the current working directory

## GITHUB configuration
GIT_OWNER="clecap"             # Owner name of the github repository for the installation
GIT_REPO="dante-wiki"          # Github repository from which we will install
GIT_BRANCH="master"            # Branch which we will install


GH_SPEC="ghcr.io/clecap/dantewiki:${TAG}"       # specification to be used for a docker pull from github
DH_SPEC="docker.io/clecap/dante-wiki:${TAG}"    # specification to be used for a docker pull from docker hub


##
## CALCULATED PARAMETERS
##
INSTALL_DIR="${PWD}/${MAIN_DIR}"


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"                                # directory where this script resides wherever it is called from
TOP_DIR=${DIR}/..                                                                      # top directory of the entire repository
source $DIR/library.sh || { echo "ERROR: could not read $DIR/library.sh"; exit 1; }    # load shell library

##
## PARAMETER PICKUP and HANDLING
##

if [ $# -lt 2 ]; then
  usage
  exit 1
fi

METHOD="$1"
CONFIGURATION="$2"

case "$METHOD" in
  pull-dh) SPEC="$DH_SPEC" ;;
  pull-gh) SPEC="$GH_SPEC" ;;
  *)       printf "${ERROR}*** Unknown method: $METHOD ${RESET}\n"; exit 1 ;;
esac

# We want to prevent this scenario: The remote ssh has shut down and we nevertheless continue installation
# Different from original intention we install a configuration on a machine for which it was not meant
if [ "$(hostname)" != "$CONFIGURATION" ]; then
  printf "${ERROR}*** WARNING: current hostname '$(hostname)' does not match configuration '${CONFIGURATION}'${RESET}\n"
  askConfirmation " *** Hostname mismatch — are you sure you want to continue?"
fi



set -e
trap 'abort' ERR

##
## MAIN function
##

printBanner

start "Doing a docker pull for ${SPEC}"
  docker pull ${SPEC}
ok "Pulled"

start "Providing information on the specified image ${SPEC}"
  getImageInfo "${SPEC}"
ok "Provided information on ${SPEC}"

start "Downloading and decrypting configuration"
  mkdir -p private && chmod 755 private
  export CONFIG_ENCRYPTED_URL="https://iuk.one/configuration-${CONFIGURATION}.sh.enc"
  read -s -p "Password for decrypting configuration file: " CONFIG_DECRYPTION_KEY && export CONFIG_DECRYPTION_KEY
  docker compose -f "$TOP_DIR/compose/docker-compose-configure.yaml" run --rm get-configuration
ok "Downloading and decrypting configuration"

start "Reading in the active configuration"
  source ${TOP_DIR}/private/configuration.sh
ok "Read the active configuration"

start "Removing all docker services for a clean restart (allowing for user abort)"
  downAllServices $TOP_DIR/compose/docker-compose-development.yaml  
ok "Removed all services"



# TODO: research if we can also do this with -d for detached mode and make better use of the health check dependency in the yaml file
#  docker compose -f $TOP_DIR/composer/docker-compose-development.yaml up -d

DOCKER_SERVICES="database webserver-raw-https phpmyadmin"

start  "Starting docker services"
  upServices $TOP_DIR/compose/docker-compose-development.yaml ${DOCKER_SERVICES}
  waitForWebserverServicing
ok "Docker services are running"

openChrome