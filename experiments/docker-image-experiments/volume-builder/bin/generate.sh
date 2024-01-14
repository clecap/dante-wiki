#!/bin/bash

# generate a local docker image for the docker context in images/${CONTAINER_NAME}/src

IMAGE_NAME=volume-builder

# get directory this shell is running in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR="${DIR}/../../../"


# cp ${TOP_DIR}/volumes/full/spec/script-library.sh ${DIR}/../src/copy-of-script-library.sh

echo ""
echo "BUILDING image with name ${IMAGE_NAME} from docker context at ${DIR}/../src"
echo ""

docker build -t ${IMAGE_NAME} --no-cache  ${DIR}/../src

echo " "; echo "DONE" ; echo " "
