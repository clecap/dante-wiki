#!/bin/bash

# TODO: USE branches in github and tags in docker hub !!!

printf "\n\nThis is dante-wiki/dist/get.sh version 2.31\n\n"  # As freshness check during development

# branch we are checking out from github
BRANCH=master

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 
printf "TOP_DIR used is ${TOP_DIR}\n"
printf "DIR used is ${DIR}\n"


if [ ! -f "${TOP_DIR}/private/configuration.sh" ]; then
  printf "Error: Configuration file ${TOP_DIR}/private/configuration.sh does not exist\n"
  printf "       Please read instructions on how to add configuration file\n"
  exit 1
elif [ $(stat -c%s "${TOP_DIR}/private/configuration.sh") -lt 20 ]; then
  printf "Error: Configuration file ${TOP_DIR}/private/configuration.sh is smaller than 20 bytes. Probably you forgot to adjust it?\n"
  printf "       Please read instructions on how to add configuration file\n"
  exit 1
else
  printf "Using configuration file ${TOP_DIR}/private/configuration.sh \n"
fi

printf "Reading configuration file ${TOP_DIR}/private/configuration.sh..."
  source ${TOP_DIR}/private/configuration.sh
printf "DONE\n"

IMAGE="clecap/dantewiki:latest"

export IMAGE_ID=$(docker images ${IMAGE} --format "{{.ID}}")
export IMAGE_DIGEST=$(docker images ${IMAGE} --format "{{.Digest}}")
export IMAGE_REPOSITORY=$(docker images ${IMAGE} --format "{{.Repository}}")
export IMAGE_CREATED_AT=$(docker images ${IMAGE} --format "{{.CreatedAt}}")
export IMAGE_TAG==$(docker images ${IMAGE} --format "{{.Tag}}")

docker compose -f ${TOP_DIR}/dist/docker-compose-development.yaml up -d database webserver-raw-${HOST_PROTOCOL}
