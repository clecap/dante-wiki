#!/bin/bash

# run a lap image in a container serving files from a local directory or from a docker volume
#
# serves files from ${MOUNT} 
# gets these files by attaching the volume with name ${VOLUME_NAME} at ${MOUNT}
#

MODE=PHP
export MODE

PORT_HTTP=8080
PORT_HTTPS=4443

IMAGE_NAME=lap

usage() {
  echo "lap/run.sh serves files from a local directory or from a docker volume "
  echo "  $0 --dir DIR_NAME               serve from directory DIR_NAME "
  echo "  $0 --vol VOLUME_NAME            serve from volume VOLUME_NAME, leaving volume untouched "
  echo "  $0 --cleanvol VOLUME_NAME       serve from volume VOLUME_NAME, cleaning volume before the run"
  echo "  Image used is local image ${IMAGE_NAME}"
  echo "  To use image from docker hub repository clecap, add option   --docker"
  exit 1
}

if [ "$#" -eq 0 ]; then    # No parameter given, do a usage
  echo "No parameter"
  usage
else                       # Called with parameters.
  case $1 in 
    (--dir) 
      DIR_NAME=$2;;
    (--vol) 
      VOLUME_NAME=$2;;
    (--cleanvol)
      MUST_CLEAN=doit
      VOLUME_NAME=$2;;
    (--docker)
      IMAGE_NAME="clecap/${IMAGE_NAME}";;
    (*) 
       echo "Error parsing options - aborting" 
       usage 
  esac
fi

# mount starting point in the case when we are using a directory
MOUNT_DIR=/var/www/html

# mount starting point in the case when we are using a volume
MOUNT_VOL=/var/www/html

# Name of the local docker network to be used
NETWORK_NAME=dante-network

# name of the generated container
CONTAINER_NAME=my-lap-container

# name of the host 
HOST_NAME=my-lap-container

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TOP_DIR="${DIR}/../../../"

echo "*** Cleaning up existing running ressources"
echo -n "*    Stopping container: "
# -t 0 is reasonable since the LAP can be shot down quickly
docker container stop ${CONTAINER_NAME} -t 0

echo -n "*    Removing container ${CONTAINER_NAME}: "
docker container rm   ${CONTAINER_NAME}
echo "DONE removing container" 

if [ "$MUST_CLEAN" == "doit" ]; then
  echo ""
  echo "*** REMOVING volume ${VOLUME_NAME}"
  docker volume rm ${VOLUME_NAME}
fi

echo "*** Running docker image ${IMAGE_NAME} as container ${CONTAINER_NAME}"

if [ -z "$NETWORK_NAME" ]; then NET_SPEC=""; else NET_SPEC="--network ${NETWORK_NAME}"; fi

if [ -z "$DIR_NAME" ]; then  
  VOL_SPEC="--volume ${VOLUME_NAME}:/${MOUNT_VOL}" 
else 
  VOL_SPEC="--volume ${DIR}/../../../volumes/${DIR_NAME}/content:${MOUNT_DIR} "
fi

echo "NET specification: ${NET_SPEC}"
echo "VOL specification: ${VOL_SPEC}"
echo ""

echo "*** Creating LAP container and got id= " `
docker run -d --name ${CONTAINER_NAME} \
  -p  ${PORT_HTTP}:80                       \
  -p ${PORT_HTTPS}:443                      \
  ${NET_SPEC}                     \
  ${VOL_SPEC}                     \
  -h ${HOST_NAME}                 \
  --env MODE=${MODE}              \
  ${IMAGE_NAME}  `


#if [ `uname` == "Darwin" ]; then 
#  echo ""; echo "*** Attempting to start a local Chrome browser - this may fail"; echo "";
#
#  # DIR_NAME is empty and we are working on a volume
#  if [ -z "$DIR_NAME" ]; then
#    open -a "Google Chrome"  http://localhost:${PORT_HTTP}/index.html
#  fi
#
#  if [ -z "$VOLUME_NAME" ]; then
#    open -a "Google Chrome"  http://localhost:${PORT_HTTP}/index.html
#  fi
#fi
