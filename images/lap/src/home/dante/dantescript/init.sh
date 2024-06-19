#!/bin/bash

# This entrypoint initializes the database, generates LocalSettings.php and runs update.php


echo " "
echo "** THIS IS /dantescript/init.sh ***** "


### set terminate on error 
abort()
{
  printf "%b" "\e[1;31m *** *** *** ABORTED *** *** *** \e[0m"
  exit 1
}
set -e                                  # abort execution on any error
trap 'abort' EXIT                       # call abort on EXIT




###### send mail upon completion ????
#### favicon must be included into the thing - and at the dockerfile level ## todo

#### check if we are already initialized ##### TODO

####### crontab entries for backup and for job queue TODO

MOUNT=/var/www/html/
TARGET=wiki-dir

####### TODO: directory where to pick up the minimal initial contents
  CONT=/home/dante/initial-contents/generic 



### TODO: really ??????
rm -f LocalSettings.php


MEDIAWIKI_DB_HOST=my-dante-mysql
MEDIAWIKI_DB_TYPE=mysql
MEDIAWIKI_DB_NAME=${MY_DB_NAME}
MEDIAWIKI_DB_PORT=3306
MEDIAWIKI_DB_USER=${MY_DB_USER}
MEDIAWIKI_DB_PASSWORD=${MY_DB_PASS}

MEDIAWIKI_RUN_UPDATE_SCRIPT=true

MEDIAWIKI_SITE_NAME="${MW_SITE_NAME}"



MEDIAWIKI_SITE_SERVER=${MW_SITE_SERVER}
MEDIAWIKI_SCRIPT_PATH="/${TARGET}"
# TODO: make language variable inputable into script
MEDIAWIKI_SITE_LANG=en
MEDIAWIKI_ADMIN_USER=${WK_ADMIN_USER}
MEDIAWIKI_ADMIN_PASS=${WK_ADMIN_PASS}
MEDIAWIKI_ENABLE_SSL=true


echo ""
echo ________________
echo "*** MEDIAWIKI INSTALLATION PARAMETERS WILL BE: "
echo ""
echo  "DATABASE Parameters are: "
echo  "   MEDIAWIKI_DB_HOST            ${MEDIAWIKI_DB_HOST}"
echo  "   MEDIAWIKI_DB_TYPE            ${MEDIAWIKI_DB_TYPE}"
echo  "   MEDIAWIKI_DB_NAME            ${MEDIAWIKI_DB_NAME}"
echo  "   MEDIAWIKI_DB_PORT            ${MEDIAWIKI_DB_PORT}" 
echo  "   MEDIAWIKI_DB_USER            ${MEDIAWIKI_DB_USER}"
echo  "   MEDIAWIKI_DB_PASSWORD        ${MEDIAWIKI_DB_PASSWORD}"
echo  "   MEDIAWIKI_RUN_UPDATE_SCRIPT  ${MEDIAWIKI_RUN_UPDATE_SCRIPT}"
echo  ""

echo "SITE Parameters are: "
echo  "   MEDIAWIKI_SITE_NAME"   ${MEDIAWIKI_SITE_NAME}
echo  "   MEDIAWIKI_SITE_SERVER  ${MEDIAWIKI_SITE_SERVER}"
echo  "   MEDIAWIKI_SCRIPT_PATH  ${MEDIAWIKI_SCRIPT_PATH}"
echo  "   MEDIAWIKI_SITE_LANG    ${MEDIAWIKI_SITE_LANG}"
echo  "   MEDIAWIKI_ADMIN_USER   ${MEDIAWIKI_ADMIN_USER}"
echo  "   MEDIAWIKI_ADMIN_PASS   ${MEDIAWIKI_ADMIN_PASS}"
echo  "   MEDIAWIKI_ENABLE_SSL   ${MEDIAWIKI_ENABLE_SSL}"
echo ""

echo "*** CALLING MEDIAWIKI INSTALL ROUTINE"
echo ""





php ${MOUNT}${TARGET}/maintenance/install.php \
    --confpath        ${MOUNT}/${TARGET} \
    --dbname         "$MEDIAWIKI_DB_NAME" \
    --dbport         "$MEDIAWIKI_DB_PORT" \
    --dbserver       "$MEDIAWIKI_DB_HOST" \
    --dbtype         "$MEDIAWIKI_DB_TYPE" \
    --dbuser         "$MEDIAWIKI_DB_USER" \
    --dbpass         "$MEDIAWIKI_DB_PASSWORD" \
    --installdbuser  "$MEDIAWIKI_DB_USER" \
    --installdbpass  "$MEDIAWIKI_DB_PASSWORD" \
    --server         "$MEDIAWIKI_SITE_SERVER" \
    --scriptpath     "$MEDIAWIKI_SCRIPT_PATH" \
    --lang           "$MEDIAWIKI_SITE_LANG" \
    --pass           "$MEDIAWIKI_ADMIN_PASS" \
    "$MEDIAWIKI_SITE_NAME" \
    "$MEDIAWIKI_ADMIN_USER"

  echo ""
  echo "________________________________  we are past maintenance/install.php __________________"
  echo ""

# check if we succeeded to generate LocalSettings.php
if [ -e "${MOUNT}/${TARGET}/LocalSettings.php" ]; then
  printf "\e[1;32m* SUCCESS:  ${MOUNT}/${TARGET}/LocalSettings.php  generated \e[0m \n"
else
  printf "\033[0;31m *ERROR:  Could not generate ${MOUNT}/${TARGET}/LocalSettings.php - *** ABORTING \033[0m\n"
fi



printf "*** Adding reference to DanteSettings.php ... "
  echo ' ' >> LocalSettings.php
  echo '###' >> LocalSettings.php
  echo '### Automagically injected by volume cmd.sh ' >> LocalSettings.php
  echo '###' >> LocalSettings.php
    # NOTE: Doing this with include does not produce an error if the file goes missing
  echo 'include (\"DanteSettings.php\"); ' >> LocalSettings.php
printf  "DONE\n\n"








# the wiki directory into which we clone the files
WIKI=${DIR}/../content/wiki-dir

# the name of the branch to which we will clone
BRANCH=master

# the local git we use for all of this
GIT_DIR=${WIKI}/.git

# the remote repository
REMOTE_REPO=https://github.com/clecap/dante-delta.git

cd ${WIKI}


# We must FIRST have a gitignore in place. If NOT then this triggers the scan of Visual Studio Codium,
#   which detects all Mediawiki files as changed (too much), shuts down the rescanning and never sees the gitignore
#
printf "*** Pick up gitignore file from repository ..."
  wget https://raw.githubusercontent.com/clecap/dante-delta/${BRANCH}/.gitignore
printf "DONE\n\n"

if [ -d "$GIT_DIR" ]; then
  printf "*** Git directory ${GIT_DIR} already exists ... nothing DONE\n\n"
else
  printf "*** Git directory ${GIT_DIR} does not exist, initializing and setting to branch master ... \n"
  git --git-dir=$GIT_DIR  init --initial-branch=$BRANCH
  git --git-dir=$GIT_DIR  remote add origin $REMOTE_REPO
###  git --git-dir=$GIT_DIR  config --local core.excludesfile ${DIR}/../../spec/git-ignore-for-delta       # configure this git to use spec/.gitignore
##  git --git-dir=$GIT_DIR  
  printf "DONE initializing a git\n\n"
fi

printf "*** Fetching origin ... "
git --git-dir=$GIT_DIR --work-tree=${WIKI} fetch origin
printf "DONE fetching origin\n\n"

printf "*** Hard reset on local git ... "
  git --git-dir=$GIT_DIR --work-tree=${WIKI}  reset --hard origin/master
printf "DONE hard reset\n\n"

printf "*** Pulling from ${BRANCH} ..."
  git --git-dir=$GIT_DIR --work-tree=${WIKI}  pull origin master
printf "DONE pulling \n\n"

printf "*** Push once to connect..."
  git push --set-upstream origin master
printf "DONE pushing once\n\n"

printf "\033[1;32m completed git-pull-from-delta.sh \033[0m \n"










######## TODO #   docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/importTextFiles.php --prefix "MediaWiki:ParsifalTemplate/" --rc --overwrite ${MOUNT}${TARGET}/extensions/Parsifal/initial-templates/*

php ${MOUNT}${TARGET}/maintenance/importDump.php --namespaces '8' --debug $CONT/minimal-initial-contents.xml
php ${MOUNT}${TARGET}/maintenance/importDump.php --namespaces '10' --debug $CONT/minimal-initial-contents.xml
php ${MOUNT}${TARGET}/maintenance/importDump.php --uploads --debug $CONT/minimal-initial-contents.xml

# main page and sidebar need a separate check in to show the proper dates
php ${MOUNT}/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite --prefix "MediaWiki:" $CONT/Sidebar
php ${MOUNT}/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite  $CONT/Main Page

# Must do an update, since we have installed all kinds of extensions earlier
printf "\n\n*** Doing a mediawiki maintenance update ... "
  php ${MOUNT}/${TARGET}/maintenance/update.php
printf "DONE"




printf "*** Importing initial set of Parsifal templates..."
  php ${MOUNT}/${TARGET}/maintenance/importTextFiles.php --prefix "MediaWiki:ParsifalTemplate/" --rc --overwrite extensions/Parsifal/initial-templates/*
printf " DONE\n"



printf "\n\n**** RUNNING: initSiteStats \n"
  php ${MOUNT}/${TARGET}/maintenance/initSiteStats.php --update
printf "DONE\n"

printf "\n\n**** RUNNING: rebuildall \n"
  php ${MOUNT}/${TARGET}/maintenance/rebuildall.php 
printf "DONE\n"

printf "\n\n**** RUNNING: checkImages \n"
  php ${MOUNT}/${TARGET}/maintenance/checkImages.php
printf "DONE\n"

printf "\n\n**** RUNNING: refreshFileHeaders \n"
  php ${MOUNT}/${TARGET}/maintenance/refreshFileHeaders.php --verbose
printf "DONE\n"


# touch the file LocalSettings.php to refresh the cache
touch ${MOUNT}/${TARGET}/LocalSettings.php"