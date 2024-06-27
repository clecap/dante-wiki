#!/bin/bash


source /home/dante/dantescript/common-defs.sh

TOP_DIR=$1
URL=$2
NAME=$3
BRANCH=$4

git config --global http.postBuffer 524288000
git config --global core.packedGitLimit 512m
git config --global core.packedGitWindowSize 512m
git config --global pack.deltaCacheSize 2047m
git config --global pack.packSizeLimit 2047m
git config --global pack.windowMemory 2047m

rm -Rf ${TOP_DIR}/extensions/${NAME}
git clone --depth 1 ${URL} --branch ${BRANCH} ${TOP_DIR}/extensions/${NAME}

# Removing .git to save on space
rm -Rf ${TOP_DIR}/extensions/${NAME}/.git

#  Injecting installation into DanteDynamicInstalls
echo "wfLoadExtension( '${NAME}' );" >> ${TOP_DIR}/DanteDynamicInstalls.php 


