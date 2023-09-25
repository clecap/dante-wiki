#!/bin/bash

## create a docker volume on the local docker engine
#  fill it with predetermined content from directory volumes/${VOLUME_NAME}
#  call script ${VOLUME_NAME}/spec/cmd.sh for further install steps
# 
## Call it: local-volume.sh VOLUME_NAME


if [ "$#" -eq 1 ]; then
  VOLUME_NAME=$1
  AVZN="eu-central-1a"
else
  echo "Usage: $0 name-of-volume" >&2
  exit 1
fi

# name of the temporary container executing the transfer
TEMP=temporary-container-for-volume-${VOLUME_NAME}
MOUNT=mountpoint

##
## CLEANUP
##
echo -n "Stopping any existing temporary container of that name: ${TEMP}..."
docker stop ${TEMP}
echo "...DONE"
echo -n "Removing any existing temporary container of that name: ${TEMP}..."
docker rm   ${TEMP}
echo "...DONE"
echo -n "Removing existing volume of that name: ${VOLUME_NAME}..."
docker volume rm ${VOLUME_NAME}
echo "...DONE"

##
## STARTING service job running the alpine OS
##
echo -n "Starting a temporary container ${TEMP} for ${VOLUME_NAME}"
docker run --name ${TEMP} -d -t --volume ${VOLUME_NAME}:/${MOUNT} alpine
# Install certificates to allow proper access to https sites
docker exec ${TEMP} apk add ca-certificates

echo
echo _____
echo "Will now copy from volumes/${VOLUME_NAME}/content/. into ${VOLUME_NAME}:/"
# NOTE: we copy into the mount point at the container, not into the volume
docker cp volumes/${VOLUME_NAME}/content/. ${TEMP}:/${MOUNT}
echo

echo
echo _____
echo "Now calling extensive specification on ${TEMP} and ${MOUNT}"
source volumes/${VOLUME_NAME}/spec/cmd.sh ${TEMP} ${MOUNT} ${VOLUME}
echo

##
## POST CLEANUP
##
echo -n "Stopping temporary container ${TEMP}..."
docker stop ${TEMP}
echo "...DONE"
echo -n "Removing temporary container ${TEMP}..."
docker rm   ${TEMP}
echo "...DONE"

