#!/bin/bash
#
# generate a public, private key pair for logging in into the container and copy the public key into the docker context directory
#

IMAGE_NAME=tex

# get directory this shell is running in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""; echo "BUILDING image with name ${IMAGE_NAME} from docker context at ${DIR}/../src"; echo ""

docker build -t ${IMAGE_NAME} ${DIR}/../src

echo " "; echo "DONE" ; echo " "
