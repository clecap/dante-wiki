#!/bin/sh

FAMILY_NAME=$1
echo "Running: ${FAMILY_NAME}"

#docker volume create my-vol

VOLUME_NAME="my-volume-name-test"

##
## populate volume
##
# create a temporary container with a busybox, inside create a volume of name ${VOLUME_NAME}
docker container create --name temp --volume ${VOLUME_NAME}:/daten busybox
docker cp ${FAMILY_NAME}/efs/. temp:/daten

# remove the temporary container
docker rm temp

docker network   rm   mynetwork-${FAMILY_NAME}
# docker network create mynetwork-${FAMILY_NAME}

docker run  \
  -p 80:80 -td  \
  --name ${FAMILY_NAME}                                      \
  --mount source=${VOLUME_NAME},target=/var/www/html                 \
${FAMILY_NAME}  \
  
