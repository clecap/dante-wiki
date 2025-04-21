#!/bin/bash

# TODO: USE branches in github and tags in docker hub !!!

printf "\n\nThis is dante-wiki/dist/get.sh version 2.3\n\n"  # As freshness check during development

# branch we are checking out from github
BRANCH=master

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 
printf "TOP_DIR used is ${TOP_DIR}\n"
printf "DIR used is ${DIR}\n"

if [ -f "${TOP_DIR}/private/configuration.shc" ] && [ $(stat -c%s "${TOP_DIR}/private/configuration.sh") -lt 20 ]; then
  printf "Error: Configuration file is smaller than 20 bytes, did you forget to adjust it?"
  exit -1
else
  printf "Using configuration file ${TOP_DIR}/private/configuration.sh\n"
fi

printf "Reading configuration file..."
  source ${TOP_DIR}/private/configuration.sh
printf "DONE\n"




docker compose -f ${TOP_DIR}/dist/docker-compose-development.yaml up -d database webserver-raw-${HOST_PROTOCOL}
