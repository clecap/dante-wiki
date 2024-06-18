#!/bin/bash

# This entrypoint initializes the database, generates LocalSettings.php and runs update.php


echo " "
echo "** THIS IS /dantescript/init.sh ***** "


rm -f LocalSettings.php

runMWInstallScript 


MEDIAWIKI_DB_HOST=my-dante-mysql
MEDIAWIKI_DB_TYPE=mysql
MEDIAWIKI_DB_NAME=${MY_DB_NAME}
MEDIAWIKI_DB_PORT=3306
MEDIAWIKI_DB_USER=${MY_DB_USER}
MEDIAWIKI_DB_PASSWORD=${MY_DB_PASS}

MEDIAWIKI_RUN_UPDATE_SCRIPT=true

MEDIAWIKI_SITE_NAME="${MW_SITE_NAME}"



MEDIAWIKI_SITE_SERVER=${MW_SITE_SERVER}
MEDIAWIKI_SCRIPT_PATH="/${VOLUME_PATH}"
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

MOUNT=/var/www/html/
VOLUME_PATH=/wiki-dir

php ${MOUNT}${VOLUME_PATH}/maintenance/install.php \
    --confpath        ${MOUNT}/${VOLUME_PATH} \
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
if [ -e "${MOUNT}/${VOLUME_PATH}/LocalSettings.php" ]; then
  printf "\e[1;32m* SUCCESS:  ${MOUNT}/${VOLUME_PATH}/LocalSettings.php  generated \e[0m \n"
else
  printf "\033[0;31m *ERROR:  Could not generate ${MOUNT}/${VOLUME_PATH}/LocalSettings.php - *** ABORTING \033[0m\n"
fi



printf "*** Adding reference to DanteSettings.php ... "
  echo ' ' >> LocalSettings.php
  echo '###' >> LocalSettings.php
  echo '### Automagically injected by volume cmd.sh ' >> LocalSettings.php
  echo '###' >> LocalSettings.php
    # NOTE: Doing this with include does not produce an error if the file goes missing
  echo 'include (\"DanteSettings.php\"); ' >> LocalSettings.php
printf  "DONE\n\n"



printf "\n\n*** Doing a mediawiki maintenance update ... "
  php ${MOUNT}${VOLUME_PATH}/maintenance/update.php
printf "DONE"


printf "*** Importing initial set of Parsifal templates..."
  php maintenance/importTextFiles.php --prefix "MediaWiki:ParsifalTemplate/" --rc --overwrite extensions/Parsifal/initial-templates/*
printf " DONE\n"

  php ${MOUNT}${VOLUME_PATH}/maintenance/importDump.php --namespaces '8' --debug assets/minimal-initial-contents.xml
  php ${MOUNT}${VOLUME_PATH}/maintenance/importDump.php --namespaces '10' --debug assets/minimal-initial-contents.xml
  php ${MOUNT}${VOLUME_PATH}/maintenance/importDump.php --uploads --debug assets/minimal-initial-contents.xml

  # main page and sidebar need a separate check in to be up to date properly
  php ${MOUNT}${VOLUME_PATH}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite --prefix "MediaWiki:" assets/Sidebar
  php ${MOUNT}${VOLUME_PATH}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite assets/Main Page

  printf "\n\n**** RUNNING: initSiteStats \n"
    php ${MOUNT}${VOLUME_PATH}/maintenance/initSiteStats.php --update
  printf "DONE\n"

  printf "\n\n**** RUNNING: rebuildall \n"
    php ${MOUNT}${VOLUME_PATH}/maintenance/rebuildall.php 
  printf "DONE\n"

  printf "\n\n**** RUNNING: checkImages \n"
    php ${MOUNT}${VOLUME_PATH}/maintenance/checkImages.php
  printf "DONE\n"

  printf "\n\n**** RUNNING: refreshFileHeaders \n"
    php ${MOUNT}${VOLUME_PATH}/maintenance/refreshFileHeaders.php --verbose
  printf "DONE\n"
