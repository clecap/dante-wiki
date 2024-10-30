#!/bin/bash

# TODO: USE branches in github and tags in docker hub !!!

# branch we are checking out from github
BRANCH=master

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 


if [ -f "${TOP_DIR}/private/configuration.shc" ] && [ $(stat -c%s "${TOP_DIR}/private/configuration.sh") -lt 20 ]; then
  printf "Error: Configuration file is smaller than 20 bytes, did you forget to adjust it?"
fi

source ${TOPD_DIR}/private/configuration.sh

docker compose -f ${TOP_DIR}/dist/docker-compose-development.yaml up -d database webserver-raw-${HOST_PROTOCOL}
