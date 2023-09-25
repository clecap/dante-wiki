#!/bin/bash

# run local docker image for the docker context in images/${CONTAINER_NAME}/src
# 

################# DEPRECATE THIS MAYBE 

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 IMAGE_NAME   CONTAINER_NAME   " >&2
 
  echo "Enter name of the image which shall be run"
  read -p IMAGE_NAME

  echo "Enter name of the container which is running the image"
  read -p CONTAINER_NAME
else
  IMAGE_NAME=$1
  CONTAINER_NAME=$2
fi

VOLUME_NAME=voluname
MOUNT=/var/mysql

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

docker container stop ${CONTAINER_NAME}
docker container rm   ${CONTAINER_NAME}

docker network   rm   dante-network
docker network create dante-network


echo "running docker"

docker run -d --name ${CONTAINER_NAME}                           \
  --network dante-network                                        \
  -p 22:22 -p 80:80 -p 443:443                                   \
  --volume ${VOLUME_NAME}:/${MOUNT} \
  ${CONTAINER_NAME}                          

