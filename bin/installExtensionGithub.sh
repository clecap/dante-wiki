#!/bin/bash

# Installs a wiki extension to the TARGET in /volume

#  for example    installExtensionGithub.sh  https://github.com/wikimedia/mediawiki-extensions-RandomSelection               RandomSelection     REL1_39


#  installExtensionGithub.sh   https://github.com/wikimedia/mediawiki-extensions-WikiCategoryTagCloud  WikiCategoryTagCloud  REL1_39


# installExtensionGithub.sh   https://github.com/clecap/dantewiki-extensions-GraphicalcategoryBrowser  GraphicalCategoryBrowser  master



# get directory where this script resides, wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR="${DIR}/../"


# mount point of the volume or directory
MOUNT="/var/www/html"

# Names of the images which we assume are running
LAP_CONTAINER=my-lap-container

VOLUME_PATH=wiki-dir

printf "\n\n*** reading in the script library..."
  source ${TOP_DIR}/volumes/full/spec/script-library.sh
printf "DONE\n\n"

printf "\n\n*** Ensure buffer is large enough on a global scale in any case\..."
  git config --global http.postBuffer 524288000
printf "DONE\n\n"



installExtensionGithub $1 $2 $3

 docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}   sh -c " composer update"