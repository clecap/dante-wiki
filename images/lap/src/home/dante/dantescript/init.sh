#!/bin/bash

# This entrypoint initializes the database, generates LocalSettings.php and runs update.php


PARSIFAL_BRANCH="dante"



echo " "
echo "** THIS IS /dantescript/init.sh ***** "


### set terminate on error 
abort()
{
  printf "%b" "\e[1;31m *** *** *** ABORTED *** *** *** \e[0m"
  exit 1
}

## set -e                                  # abort execution on any error
## trap 'abort' EXIT                       # call abort on EXIT


###### send mail upon completion ????
#### favicon must be included into the thing - and at the dockerfile level ## todo
#### check if we are already initialized ##### TODO
####### crontab entries for backup and for job queue TODO

MOUNT=/var/www/html/
TARGET=wiki-dir

# directory where to pick up the minimal initial contents
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

############# TODO !!
MEDIAWIKI_ENABLE_SSL=false

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

echo " "
echo " " 

##
## Install Parsifal development version
##
printf "\n*** Cloning Parsifal from branch $PARSIFAL_BRANCH ... \n"
  git clone --depth 1 --branch $PARSIFAL_BRANCH https://github.com/clecap/Parsifal ${MOUNT}/$TARGET/extensions
printf "DONE cloning branch $BRANCH of Parsifal\n\n"


################## TODO: we must ensure that this leads to an error / ABORT if the branch does not exist 
################ TODO: we need to get a clear abort in numersou situations - and TODO clean up the existin live area before filling it in !!!!!!
######## CAVE not delete too much !!!!!





printf "*** Adding reference to DanteSettings.php ... "
  echo ' ' >> LocalSettings.php
  echo '###' >> LocalSettings.php
  echo '### Automagically injected by volume cmd.sh ' >> LocalSettings.php
  echo '###' >> LocalSettings.php
    # NOTE: Doing this with include does not produce an error if the file goes missing
  echo 'include (\"DanteSettings.php\"); ' >> LocalSettings.php
printf  "DONE\n\n"

printf "*** Adding initial contents..."
  php ${MOUNT}${TARGET}/maintenance/importDump.php --namespaces '8' --debug $CONT/minimal-initial-contents.xml
  printf " namespace 8 done ";
  php ${MOUNT}${TARGET}/maintenance/importDump.php --namespaces '10' --debug $CONT/minimal-initial-contents.xml
  printf " namespace 10 done ";
  php ${MOUNT}${TARGET}/maintenance/importDump.php --uploads --debug $CONT/minimal-initial-contents.xml
  printf " uploads done ";
printf "DONE\n\n"

# main page and sidebar need a separate check in to show the proper dates
printf "*** Checking in sidebar..."
   php ${MOUNT}/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite --prefix "MediaWiki:" $CONT/Sidebar
printf "DONE\n\n"

printf "*** Checking in MainPage..."
  php ${MOUNT}/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite  $CONT/Main Page
printf "DONE\n\n"

# Must do an update, since we have installed all kinds of extensions earlier
printf "\n\n*** Doing a mediawiki maintenance update ... "
  php ${MOUNT}/${TARGET}/maintenance/update.php
printf "DONE update.php\n\n"


# parsifal is not yet installed at this place - so do not yet do this TODO
####
####printf "*** Importing initial set of Parsifal templates..."
####  php ${MOUNT}/${TARGET}/maintenance/importTextFiles.php --prefix "MediaWiki:ParsifalTemplate/" --rc --overwrite extensions/Parsifal/initial-templates/*
#### printf " DONE\n"



printf "\n\n**** RUNNING: initSiteStats \n"
  php ${MOUNT}/${TARGET}/maintenance/initSiteStats.php --update
printf "DONE initSiteStats.php\n"

printf "\n\n**** RUNNING: rebuildall \n\n"
  php ${MOUNT}/${TARGET}/maintenance/rebuildall.php 
printf "\n----DONE rebuildall.php\n\n"

printf "\n\n**** RUNNING: checkImages \n"
  php ${MOUNT}/${TARGET}/maintenance/checkImages.php
printf "\n----DONE checkImages.php\n"

printf "\n\n**** RUNNING: refreshFileHeaders \n"
  php ${MOUNT}/${TARGET}/maintenance/refreshFileHeaders.php --verbose
printf "\n----DONE refreshFileHeaders.php\n\n"

# touch the file LocalSettings.php to refresh the cache
printf "\n\n**** Touching LocalSettings.php to refresh the cache..."
touch ${MOUNT}/${TARGET}/LocalSettings.php
printf "\n----DONE touching LocalSettings.php\n\n"



printf "\n\n*** /home/dante/dantescript/init.sh COMPLETED \n\n"