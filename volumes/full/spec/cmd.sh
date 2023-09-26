#!/bin/bash

# configurable shell script which builds up content in /volumes/full/content
# it takes no parameters

### CAVE: THIS file generates static content in the volume / filesystem but does NO database related and NO dynamic stuff


# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TOPDIR="${DIR}/../../../"

source ${DIR}/script-library.sh


abort()
{
  printf "%b" "\e[1;31m *** CLONING FROM DELTA WAS ABORTED *** \e[0m"
  exit 1
}

set -e                                  # abort execution on any error
trap 'abort' EXIT                       # call abort on EXIT





cleanUp () { # Code to clean up this directory
  printf "\n*** Cleaning up volume at ${TOPDIR} \n\n"
  # git somteimes produces awkward permissions
  if [ -d "${TOPDIR}/volumes/full/content/${TARGET}.git" ]; then
    chmod -R a+w ${TOPDIR}/volumes/full/content/${TARGET}.git
  fi
  printf "Will remove ${TOPDIR}/volumes/full/content/*  \n"
  rm -Rf ${TOPDIR}volumes/full/content/*
  printf "DONE content/*\n"
  rm -Rf ${TOPDIR}volumes/full/content/*.git
  printf "DONE content/*.git\n"
  rm -f ${TOPDIR}volumes/full/content/.gitignore
  printf "DONE content/.gitignore\n"
  printf "DONE cleaning up\n\n"

  mkdir -p ${TOPDIR}volumes/full/content/wiki-dir
  # we must clone from dante-delta to have the correct gitignore in place so that visual studio codium works correctly
  source ${TOPDIR}/volumes/full/spec/git-clone-from-delta.sh 
  source ${TOPDIR}/volumes/full/spec/git-clone-from-parsifal.sh 
}



makeWiki () { # Installs mediawiki directly from the network
  ##           call as  makeWiki  MAJOR  MINOR  TARGET
  ##           example:  makeWiki 1.38.0 wiki-dir
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
    # must not have more .git directories than necessary   TODO: maybe use a different command then
  rm -Rf Modern/.git
  echo "wfLoadSkin( 'Modern' );" >> ${TOP}/DanteSkinsInstalled.php

  # Refreshed
  echo ""; echo "*** Installing skin Refreshed"
  mkdir Refreshed
  git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/Refreshed Refreshed
    # must not have more .git directories than necessary  TODO: maybe use a 
  rm -Rf Refreshed/.git
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

  printf "\n *** Installing drawio external service"
  mkdir -p ${DIR}/../content/${TARGET}/external-services/draw-io/
  echo "  mkdir done"
  wget https://github.com/clecap/drawio/archive/refs/heads/dev.zip -O ${DIR}/../content/${TARGET}/external-services/dev.zip
  unzip -q ${DIR}/../content/${TARGET}/external-services/dev.zip -d ${DIR}/../content/${TARGET}/external-services/draw-io/
  rm ${DIR}/../content/${TARGET}/external-services/dev.zip
  echo "DONE installing drawio external service\n"
}






##
## Install Mediawiki files
##


cleanUp 

makeWikiLocal 1.39 0 wiki-dir

getSkins wiki-dir

addingImages wiki-dir

installingDrawio wiki-dir


printf "*** copying some private credentials from main directory into volume\n"
if [ -e ${DIR}/../../../conf/mediawiki-PRIVATE.php ]
then
  cp ${DIR}/../../../conf/mediawiki-PRIVATE.php ${DIR}/../content/wiki-dir/mediawiki-PRIVATE.sh
else
  cp ${DIR}/../../../conf/mediawiki-SAMPLE.php ${DIR}/../content/wiki-dir/mediawiki-PRIVATE.sh
fi


printf "DONE copying in\n\n"


## simpleEntryPage


##getWP word



echo ""
echo "*** COMPLETED: generation of volume   cmd.sh"
echo ""


# makeWP 6.1.1 wp-dir