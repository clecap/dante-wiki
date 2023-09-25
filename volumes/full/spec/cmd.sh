#!/bin/bash

# configurable shell script which builds up content in /volumes/full/content
# it takes no parameters

### CAVE: THIS file generates static content in the volume / filesystem but does NO database related and NO dynamic stuff


# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


source ${DIR}/script-library.sh


# region cleanUp: Code to clean up this directory
# region
cleanUp () {
  echo "Making ${DIR}/../../../vendor"
  mkdir -p ${DIR}/../../../vendor
  rm -Rf ${DIR}/../../../vendor
  mkdir -p ${DIR}/../content
  cd ${DIR}/..
  rm -Rf content/*
}
# endregion
#endregion


# region makeWiki: Installs mediawiki directly from the network
##           call as  makeWiki  MAJOR  MINOR  TARGET
##           example:  makeWiki 1.38.0 wiki-dir
# region
makeWiki () {
  WIKI_VERSION_MAJOR=$1
  WIKI_VERSION_MINOR=$2
  TARGET=$3
  WIKI_NAME=mediawiki-${WIKI_VERSION_MAJOR}.${WIKI_VERSION_MINOR}
  cd ${DIR}/../content
  mkdir -p ${TARGET}
  cd ${TARGET}
  wget https://releases.wikimedia.org/mediawiki/${WIKI_VERSION_MAJOR}/${WIKI_NAME}.tar.gz;
  tar --strip-components=1 -xzf ${WIKI_NAME}.tar.gz
  rm ./${WIKI_NAME}.tar.gz
}
# endregion
# endregion




# region getMWExtension  Installs a mediawiki extension from gerrit or github
##                 call as getMWExtension  NAME  RELEASE  TARGET  SRC
##                 example:  getMWExtension TitleKey  REL1_38  wiki-dir  gerrit
# region
getMWExtension () {
  NAME=$1
  RELEASE=$2
  TARGET=$3
  SRC=$4
  cd ${DIR}/../content
  cd ${TARGET}/extensions
  case $SRC in
    gerrit)
      git clone https://gerrit.wikimedia.org/r/mediawiki/extensions/${NAME} --branch ${RELEASE} ${NAME}
    ;;
    github)
      git clone https://github.com/wikimedia/mediawiki-extensions-${NAME} --branch ${RELEASE} ${NAME}
    ;;
    *)
      echo "" 
      echo "*** ERROR: unknown source "
  esac
  cd ${NAME}
  rm -Rf .git 
}
# endregion
# endregion


#region getSkins: get some additional skins from gerrit
getSkins () {
  TARGET=$1
  TOP=${DIR}/../content/${TARGET}
  echo "*** TOP is ${TOP}"

  MW_VERSION=REL1_37

  cd ${TOP}/skins
  echo "<?php " >> ${TOP}/DanteSkinsInstalled.php

# Chameleon skin is broken
# Chameleon
#  echo ""; echo "*** Installing skin Chameleon"
#  wget https://github.com/ProfessionalWiki/chameleon/archive/master.zip
#  unzip -q master.zip
#  mv chameleon-master chameleon
#  rm master.zip
#  echo "wfLoadSkin( 'chameleon' );" >> ${TOP}/DanteSkinsInstalled.php
#  echo ""
#  cd ${TOP}/skins

  # removed, since the skin uses a deprecated method in 1.39
  # CologneBlue
  # echo ""; echo "*** Installing skin CologneBlue"
  # mkdir CologneBlue
  # git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/CologneBlue CologneBlue 
  # echo "wfLoadSkin( 'CologneBlue' );" >> ${TOP}/DanteSkinsInstalled.php

  # Modern
  echo ""; echo "*** Installing skin Modern"
  mkdir Modern
  git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/Modern Modern
  echo "wfLoadSkin( 'Modern' );" >> ${TOP}/DanteSkinsInstalled.php

  # Refreshed
  echo ""; echo "*** Installing skin Refreshed"
  mkdir Refreshed
  git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/Refreshed Refreshed
  echo "wfLoadSkin( 'Refreshed' );" >> ${TOP}/DanteSkinsInstalled.php

}
#endregion




#region:  getWP    get wordpress command line for user $1 in directory wp-$1
getWP () {
  USERNAME=$1

  echo ""; echo "** Making local directory"
  cd ${DIR}/../content
  mkdir wp-${USERNAME}
  echo "DONE making local directory\n"

  echo "\n** Installing wordpress command line\n"
  cd ${DIR}/../content/wp-${USERNAME}
  wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod 755 wp-cli.phar
  echo "DONE installing wordpress command line\n"

  # we do not want to execute this here as this requires PHP and we want to run it not under the PHP version installed on the host but 
  # on the 
}
#endregion


#region  simpleEntyPage   dynamically generate a simple entry page
simpleEntryPage () {
  cd ${DIR}/../content
  echo "<html><head></head><body><a href='wiki-dir'>Wiki</a></body></html>" >>  index.html
}
#endregion



## Copy in some other assets
addingAssets () {
  TARGET=$1
  printf "\n*** Adding assets to target=${TARGET}\n"

  printf "\n** Adding some images\n"
  cp ${DIR}/../../../assets/favicon.ico              ${DIR}/../content/${TARGET}/favicon.ico
  cp ${DIR}/../../../assets/caravaggio-180x180.png   ${DIR}/../content/${TARGET}/logo.png
  printf "\nDONE adding some images\n"

  echo ""; echo "*** Installing drawio external service"
  mkdir -p ${DIR}/../content/${TARGET}/external-services/draw-io/
  echo "  mkdir done"
  wget https://github.com/clecap/drawio/archive/refs/heads/dev.zip -O ${DIR}/../content/${TARGET}/external-services/dev.zip
  unzip ${DIR}/../content/${TARGET}/external-services/dev.zip -d ${DIR}/../content/${TARGET}/external-services/draw-io/
  rm ${DIR}/../content/${TARGET}/external-services/dev.zip
  echo "DONE installing drawio external service"

}



##
## Install Mediawiki files
##


cleanUp 

makeWikiLocal 1.39 0 wiki-dir

getSkins wiki-dir

addingAssets wiki-dir

printf "*** copying some private credentials from main directory into volume\n"
cp ${DIR}/../../../conf/mediawiki-PRIVATE.php ${DIR}/../content/wiki-dir
printf "DONE copying in\n\n"


## simpleEntryPage


##getWP word



echo ""
echo "*** COMPLETED: generation of volume   cmd.sh"
echo ""


# makeWP 6.1.1 wp-dir