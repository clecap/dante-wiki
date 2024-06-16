#!/bin/bash

# generate a local docker image for the docker context in images/${CONTAINER_NAME}/src

IMAGE_NAME=dante-mysql

# get directory this shell is running in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "BUILDING image with name ${IMAGE_NAME} from docker context at ${DIR}/../src"
echo ""

docker build -t ${IMAGE_NAME} --no-cache  ${DIR}/../src

echo " "; echo "DONE" ; echo " "
