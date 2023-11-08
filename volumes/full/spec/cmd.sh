#!/bin/bash

# configurable shell script which builds up content in /volumes/full/content
# it takes no parameters

### CAVE: THIS file generates static content in the volume / filesystem but does NO database related and NO dynamic stuff

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR="${DIR}/../../../"

# todo !!! what is this ?
# currently used in skin installer in script-library
MW_VERSION=REL1_39

source ${TOP_DIR}/volumes/full/spec/script-library.sh

cleanUpVolume
makeWikiLocal 1.39 0 wiki-dir

# only NOW we should add the modifications
# cp ${TOP_DIR}/volumes/full/spec/git-ignore-for-delta ${TOP_DIR}/volumes/full/content/wiki-dir/.gitignore
source ${TOP_DIR}/volumes/full/spec/git-clone-from-delta.sh 
source ${TOP_DIR}/volumes/full/spec/git-clone-from-parsifal.sh 

getSkins wiki-dir
addingImages wiki-dir
installingDrawio wiki-dir

copyInMinimal wiki-dir

printf "*** copying some private credentials from main directory into volume\n"
if [ -e ${DIR}/../../../conf/mediawiki-PRIVATE.php ]
then
  cp ${DIR}/../../../conf/mediawiki-PRIVATE.php ${DIR}/../content/wiki-dir/mediawiki-PRIVATE.php
else
  cp ${DIR}/../../../conf/mediawiki-SAMPLE.php ${DIR}/../content/wiki-dir/mediawiki-PRIVATE.php
fi

simpleEntryPage

printf "DONE copying in\n\n"