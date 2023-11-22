#!/bin/bash

IMAGE_NAME=minimal

# get directory this shell is running in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker build -t ${IMAGE_NAME} ${DIR}/../src

docker scout quickview 
docker scout cves minimal:latest