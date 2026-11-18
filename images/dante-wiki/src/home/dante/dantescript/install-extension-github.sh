#!/bin/bash

source /home/dante/dantescript/common-defs.sh

set -e

printf "\n*** install-extension-github called at $1 $2 $3 $4 $5\n"

TOP_DIR=$1
URL=$2
NAME=$3
BRANCH=$4
KEEP=${5:-}   # if DEV: keep .git directory

rm -Rf ${TOP_DIR}/extensions/${NAME}
git clone --depth 1 ${URL} --branch ${BRANCH} ${TOP_DIR}/extensions/${NAME}

# Removing .git to save on space, unless KEEP is DEV
if [ "$KEEP" = "DEV" ]; then
  printf "\n*** KEEP=DEV: keeping ${TOP_DIR}/extensions/${NAME}/.git\n"
else
  rm -Rf ${TOP_DIR}/extensions/${NAME}/.git
fi

#  Injecting installation into DanteDynamicInstalls
echo "wfLoadExtension( '${NAME}' );" >> ${TOP_DIR}/DanteDynamicInstalls.php 

set +e

printf "\n*** injected into DanteDynamicInstalls \n"

