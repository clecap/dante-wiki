#!/bin/bash
  
# cleans in volume ${VOLUME_NAME} the directory ${MOUNT}/${VOLUME_PATH}
# copies the contents of directory volumes/${DIR_NAME}/content to the volume ${VOLUME_NAME} and there at path ${VOLUME_PATH}
# additionally executes shell commands in volumes/${DIR_NAME}/spec/cmd.sh

# DIR_NAME      we are copying from  volumes/${DIR_NAME}/
# VOLUME_NAME   we are copying to VOLUME_NAME
# VOLUME_PATH   we are copying to VOLUME_PATH in VOLUME_NAME

# Parse the command line  
if [ "$#" -eq 3 ]; then
  export DIR_NAME=$1
  export VOLUME_NAME=$2
  export VOLUME_PATH=$3
else
  echo "Usage: $0  DIR_NAME  VOLUME_NAME  VOLUME_PATH " >&2
  echo "Adds contents of directory DIR_NAME to volume VOLUME_NAME at VOLUME_PATH " >&2
  exit 1
fi


# region ABORT ERROR HANDLER
abort()
{
    echo >&2 '
***************
*** ABORTED ***
***************
'
    exit 1
}


main () {





## two temporary symbols
#  TEMP: Name of the temporary busybox container which does the copying
export TEMP=temporary-busybox
#  MOUNT: where is the volume mounted to the temporary copying container
export MOUNT=/mnt

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# source directory on host
SRC=${DIR}/../../volumes/${DIR_NAME}/content/.

printf "\n\n\n\n"

printf "*** Ensuring that the name of the temporary container ${TEMP} is available (may fail, is ok)..."
docker stop ${TEMP}
docker rm ${TEMP}
printf "DONE ensuring\n\n"

set -e
trap 'abort' EXIT

printf "*** Starting a temporary container ${TEMP} for ${VOLUME_NAME} at mount point ${MOUNT}..."
docker run --name ${TEMP} -d -t --volume ${VOLUME_NAME}:/${MOUNT} alpine
printf "DONE starting\n\n"

printf "*** Cleaning up existing directory ${MOUNT}/${VOLUME_PATH}..."
docker exec ${TEMP} rm -Rf ${MOUNT}/${VOLUME_PATH}/*
printf "DONE cleaning\n\n"

# NOTE: we copy into the mount point at the container, not into the volume

printf "*** Building the required directory path ${VOLUME_PATH}..."
docker exec ${TEMP} mkdir -p ${MOUNT}/${VOLUME_PATH}
printf "DONE building the required directory path\n"

printf "*** ls on ${MOUNT}..."
docker exec ${TEMP} ls ${MOUNT}
printf "DONE ls on ${MOUNT}\n\n"

printf "*** cp ${SRC}  ${TEMP}:/${MOUNT}/${VOLUME_PATH}..."
docker cp ${SRC} ${TEMP}:/${MOUNT}/${VOLUME_PATH}
printf "DONE cp\n\n"

printf "*** Setting permissions on ${MOUNT} to 100.101 for apache.apache  ..."
docker exec ${TEMP} /bin/ash -c "chown -R 100.101 ${MOUNT}"
printf "DONE fixing permissions\n\n"

printf "*** ls on ${MOUNT}..."
docker exec ${TEMP} ls -l ${MOUNT}
printf "DONE ls on ${MOUNT}\n\n"

printf "*** Stopping and removing temporary container...\n"
docker stop ${TEMP}
docker rm ${TEMP}
printf "DONE stopping and removing temporary container\n\n"

trap : EXIT         # switch trap command back to noop (:) on EXIT
}

main 