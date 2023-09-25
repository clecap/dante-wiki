#!/bin/bash

# run a mysql database on local docker infrastructure using docker context in my-mysql/src

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# load some global parameters such as passwords
source ${DIR}/../../../conf/customize-PRIVATE.sh

# for ssh into the container:
PORT=2223
#                             TODO: This is deprecated  remove !  IS IT?? REALLY ??

# for ssh  # todo: adjust
USERNAME=cap

usage() {
  echo ""
  echo "Usage: $0   "
  echo "  --db       DB_VOLUME_NAME     (use DB_VOLUME_NAME as DB volume) "
  echo "  --cleandb  DB_VOLUME_NAME     (use DB_VOLUME_NAME as DB volume and clean existing volume before use) "
  echo "  NO PARAM:  ${DEFAULT_DB_VOLUME_NAME} as DB volume and clean volume before use"
}

##
## Read command line
# region
if [ "$#" -eq 0  ]; then
  usage
  DB_VOLUME_NAME=${DEFAULT_DB_VOLUME_NAME}
  DB_MUST_CLEAN=doit
else
  if [ "$#" -le 3 ]; then
    while (($#)); do
      case $1 in 
        (--db) 
          DB_VOLUME_NAME=$2
          shift 2;;
        (--cleandb) 
          DB_VOLUME_NAME=$2
          DB_MUST_CLEAN=doit 
          shift 2;;
        (*) 
          echo "ERROR parsing options - *** aborting ****" 
          usage 
          exit 1
      esac
    done
  else
    usage
    exit 1
  fi
fi

echo ""
echo "*** DB_VOLUME_NAME  ${DB_VOLUME_NAME}  "
if [ "$DB_MUST_CLEAN" == "doit" ]; then
  echo "*** CLEANING volume before use"
else
  echo "*** NOT cleaning volume before use"
fi
echo ""



CONTAINER_NAME=my-mysql
HOST_NAME=${CONTAINER_NAME}

# mount point for the database volume
MOUNT=/var/mysql
NETWORK=dante-network


##
## CLEAN UP
##
#region
echo ""
echo "*** Cleaning up old ressources:"

echo -n "*   Stopping DB container: "
docker container stop ${CONTAINER_NAME}

echo -n "*   Removing DB container: "
docker container rm   ${CONTAINER_NAME}

echo -n "*   Stopping phpMyadmin container: "
docker container stop my-phpmyadmin-${CONTAINER_NAME}

echo -n "*   Removing phpMyadmin container: "
docker container stop my-phpmyadmin-${CONTAINER_NAME}

echo -n "*   Removing network:   "
docker network   rm   ${NETWORK}

if [ "$DB_MUST_CLEAN" == "doit" ]; then
  echo -n "*   Deleting DB volume ${DB_VOLUME_NAME}: "
  docker volume rm ${DB_VOLUME_NAME}
else
  echo "Keeping DB volume ${DB_VOLUME_NAME}"
fi
echo " "
# endregion


##
## CREATE
##

echo -n "*** Creating network ${NETWORK} and got id= "
docker network create ${NETWORK}

echo -n "*** Creating DB container ${CONTAINER_NAME} and got id= "

# export environment variables to the docker container for use there and in the entry point

## below: provide USERNAME to trigger ssh mechanism

docker run -d --name ${CONTAINER_NAME}                      \
  --network ${NETWORK}                                      \
  -h ${HOST_NAME}                                           \
  --env USERNAME=${USERNAME}                                \
  -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}"           \
  -e MYSQL_DUMP_USER="${MYSQL_DUMP_USER}"                   \
  -e MYSQL_DUMP_PASSWORD"${MYSQL_DUMP_PASSWORD}"            \
  --volume ${DB_VOLUME_NAME}:/${MOUNT}                      \
  ${CONTAINER_NAME}                          

echo ""

# TODO: not yet tested
#until [ "`docker inspect -f {{.State.Health.Status}} ${CONTAINER_NAME}`"=="healthy" ]; do
#  echo "*   Container not yet healthy, waiting..."
#  sleep 0.1;
#done;
#
#echo "*   Container health check passed"

echo -n "*** MY-MYSQL is now running at "  `docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ${CONTAINER_NAME}`
echo  "   as host ${HOST_NAME}"


echo " "



