#!/bin/bash

IMAGE_NAME=tex

source ../../../version.sh


# get directory this shell is running in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


docker build -t ${IMAGE_NAME}:latest -t ${IMAGE_NAME}:${VERSION} ${DIR}/../src

# docker scout quickview 
# docker scout cves minimal:latest