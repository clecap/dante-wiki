#!/bin/bash

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

source $DIR/library.sh

set -e
trap 'abort' ERR

source ${TOP_DIR}/private/configuration.sh

getImageInfo ${DANTE_IMAGE}

downAllServices $TOP_DIR/composer/docker-compose-development.yaml

