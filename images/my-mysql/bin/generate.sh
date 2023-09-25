#!/bin/bash

# generate a local docker image for the docker context in images/${CONTAINER_NAME}/src
# 

CONTAINER_NAME=my-mysql

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""

echo -n "*** Stopping container: "
docker container stop ${CONTAINER_NAME}

echo -n "*** Removing container:"
docker container rm   ${CONTAINER_NAME}

echo ""

echo "*** Building image"
docker build -t ${CONTAINER_NAME} ${DIR}/../src
