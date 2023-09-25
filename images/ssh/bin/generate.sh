#!/bin/bash
#
# generate docker image
#

# get directory this shell is running in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${DIR}/PARAMETERS.sh

printf "** BUILDING image with name ${IMAGE_NAME} from docker context at ${DIR}/../src \n"
printf "COMMAND IS: docker build -t ${IMAGE_NAME} ${DIR}/../src \n"
docker build -t ${IMAGE_NAME} ${DIR}/../src
printf "DONE building"
