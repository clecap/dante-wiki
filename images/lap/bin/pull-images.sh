#!/bin/bash

# run a lap image in a container serving files from a local directory or from a docker volume
#
# serves files from ${MOUNT} 
# gets these files by attaching the volume with name ${VOLUME_NAME} at ${MOUNT}
#

echo ""; echo "*** Pulling Docker Images from docker hub..."
  docker pull clecap/lap:latest
  docker pull clecap/my-mysql:latest
echo "DONE pulling docker images"

echo ""; echo "*** Retagging docker images into local names for install mechanisms..."
  docker tag clecap/lap:latest lap
  docker tag clecap/my-mysql:latest my-mysql
echo "DONE "
