#!/bin/zsh

if [ $# -eq 0 ]; then
    echo "Usage:    ./dbRestore.sh  Name-of-Dantewiki filename-of-dump "
    echo "Example:  ./dbRestore.sh  mathewiki "
    echo "Purpose:  Restore a full database dump into the data base of the respective dantewiki"
    exit 1
fi

NAME=$1
FILENAME=$2

## customize-PRIVATE.sh contains all the settings of the user for all her environment parameters
source ../conf/customize-PRIVATE.sh

## adjust sets some defaults and picks the final parameters from the provided name and the data in customize-PRIVATE.sh
source ../lib/adjust.sh


docker exec -i my-mysql-${NAME} mysql -u ${MEDIAWIKI_DB_USER} --password="${MEDIAWIKI_DB_PASSWORD}" < ${FILENAME}
