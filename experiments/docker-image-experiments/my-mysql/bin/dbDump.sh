#!/bin/zsh

if [ $# -eq 0 ]; then
    echo "Usage:    ./dbDump.sh    "
    echo "Example:  ./dbDump.sh    "
    echo "Purpose:  Write a full database dump to directory dumps, filename includes time stamp and name"
    exit 1
fi


## make this for one DB and for all DB !


NAME=$1

DEFAULT_VOLUME_NAME=my-mysql-data-volume

MYSQL_CONTAINER=${DEFAULT_VOLUME_NAME}

# MYSQL_DUMP_USER=
# MYSQL_DUMP_PASSWORD=

## customize-PRIVATE.sh contains all the settings of the user for all her environment parameters
source ../conf/customize-PRIVATE.sh

## adjust sets some defaults and picks the final parameters from the provided name and the data in customize-PRIVATE.sh
##source ../lib/adjust.sh

# prevent overwriting an existing dump file
set -o noclobber

rm -f dump-errors

# CAVE: below, do not use -t in docker exec to prevent warnings from mysqldump to show up in the sql file
#       See https://github.com/docker-library/mysql/issues/132  for more details 
docker exec -i ${MYSQL_CONTAINER} mysqldump -u ${MYSQL_DUMP_USER} --password=${MYSQL_DUMP_PASSWORD} --all-databases > ../dumps/dump-${NAME}-$(date '+%d-%m-%Y-at-%T').sql 2>dump-errors

cat dump-errors

