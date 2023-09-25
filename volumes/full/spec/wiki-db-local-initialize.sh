#!/bin/bash


## The original of this file is in the development repository

#
# Driver function which initializes the MediaWiki database and generates a local settings file
#

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source ${DIR}/script-library.sh


usage() {
  echo ""
  echo "Usage:   $0  MW_SITE_NAME  MW_SITE_SERVER  SITE_ACRONYM  WK_PASS MYSQL_ROOT_PASSWORD "
  echo "Example: $0  mysite  https://localhost:4443  acro  admin-password  sql-password "
  exit 1
}

##
## Read command line
# region
if [ "$#" -eq 0  ]; then
  usage
fi


MW_SITE_NAME=$1
MW_SITE_SERVER=$2
SITE_ACRONYM=$3
WK_PASS=$4
MYSQL_ROOT_PASSWORD=$5

echo ""; echo "*** Running wiki-db-local-initalize.sh on ${MW_SITE_NAME} ${MW_SITE_SERVER} ${SITE_ACRONYM} ${WK_PASS} ${MYSQL_ROOT_PASSWORD}"

MOUNT="/var/www/html"
VOLUME_PATH=wiki-dir
LAP_CONTAINER=my-lap-container
DB_CONTAINER=my-mysql

DB_USER=user${SITE_ACRONYM}
DB_NAME=DB_${SITE_ACRONYM}
DB_PASS=`openssl rand -base64 14`

echo ""; echo "*** DB_CONTAINER IS: ${DB_CONTAINER}"

# abort on any error
set -e

dropUser ${DB_CONTAINER} ${MYSQL_ROOT_PASSWORD} ${DB_USER}

dropDatabase ${DB_NAME} ${DB_CONTAINER} ${MYSQL_ROOT_PASSWORD}


echo "*** Calling: addDatabase DB_NAME=${DB_NAME} DB_USER=${DB_USER} DB_PASS=${DB_PASS} MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} DB_CONTAINER=${DB_CONTAINER} "

addDatabase ${DB_NAME} ${DB_USER} ${DB_PASS} ${MYSQL_ROOT_PASSWORD} ${DB_CONTAINER}

removeLocalSettings ${LAP_CONTAINER} ${MOUNT} ${VOLUME_PATH}

runMWInstallScript ${MW_SITE_NAME} ${MW_SITE_SERVER} ${SITE_ACRONYM} ${WK_PASS}

addingReferenceToDante ${MOUNT} ${VOLUME_PATH} ${LAP_CONTAINER}

