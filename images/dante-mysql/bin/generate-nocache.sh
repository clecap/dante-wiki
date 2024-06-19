#!/bin/bash

# generate a local docker image for the docker context

IMAGE_NAME=dante-mysql

TOP_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
source ${TOP_DIR}/VERSION.sh
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "VERSION: $DANTE_VERSION"

echo ""
echo "BUILDING image with name ${IMAGE_NAME} from docker context at ${DIR}/../src"
echo ""

docker build -t ${IMAGE_NAME}:latest -t ${IMAGE_NAME}:${DANTE_VERSION} --no-cache ${DIR}/../src

echo " "; echo "DONE" ; echo " "
