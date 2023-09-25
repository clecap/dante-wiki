#!/bin/bash
#
# Runs a php-myadmin container on the database
#

NAME=my-mysql
NETWORK_NAME=dante-network
PMA_HOST=my-mysql


PMA_CONTAINER_NAME=my-phpmyadmin-${NAME}

# -d   run as daemon in background
# -e   set environment variable
#
#

# TODO: maybe add https to this for more password security




echo "*** Cleaning up existing ressources"
echo -n "* Stopping container: "
# -t 0 since the LAP can be shot down quickly
docker container stop ${PMA_ONTAINER_NAME} -t 0

echo -n "*    Removing container: "
docker container rm   ${PMA_CONTAINER_NAME}
echo "" 



docker run --name ${PMA_CONTAINER_NAME} --network ${NETWORK_NAME}  -d -e PMA_HOST=${PMA_HOST}  -p 9090:80 phpmyadmin:5.0

open -a "Google Chrome" http://localhost:9090