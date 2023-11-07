#!/bin/bash

#
# This is a library of bash script functions
#


SCRIPT_LIB_VERSION=2.10


# propagate traps into called functions:
set -E

set -o functrace

# See https://stackoverflow.com/questions/24398691/how-to-get-the-real-line-number-of-a-failing-bash-command

function handle_error {
  # get exit status of last executed command
  local retval=$?
  local line=${last_lineno:-$1}
  local arg1=$1
  local arg2=$2
  local argLast=${@: -1}
  printf "\e[1;31m***\n*** ERROR at CMD $argLast in LINE: $line of FILE: ${BASH_SOURCE[1]} with STATUS: $retval \n***\n\n     STACK TRACE:\n\n"
  for i in "${!FUNCNAME[@]}"
    do
      printf "    \e[1;31m FCT %-15s called in FILE %-15s at LINE %-15s\n" ${FUNCNAME[$i]}  ${BASH_SOURCE[$i+1]}  ${BASH_LINENO[$i]}
    done
  printf "\e[0m";
  exit $retval
}

# See https://stackoverflow.com/questions/24398691/how-to-get-the-real-line-number-of-a-failing-bash-command
if (( ${BASH_VERSION%%.*} <= 3 )) || [[ ${BASH_VERSION%.*} = 4.0 ]]; then
  trap '[[ $FUNCNAME = handle_error ]] || { last_lineno=$real_lineno; real_lineno=$LINENO; }' DEBUG
fi
trap 'handle_error $LINENO ${BASH_LINENO[@]} $BASH_COMMAND' ERR



simpleEntryPage () { #  dynamically generate a simple entry page on the target-less url
  echo "<html><head></head><body><a href='wiki-dir'>Wiki</a></body></html>" >>  ${TOP_DIR}/volumes/full/content/index.html
}



getSkins () {      #  copy in skins
  TARGET=$1

  local SKIN_DIR=${TOP_DIR}/volumes/full/content/${TARGET}/skins
  cd ${SKIN_DIR}

  echo "<?php " >> ${TOP_DIR}/volumes/full/content/${TARGET}/DanteSkinsInstalled.php

  # Modern
  printf "*** Installing skin Modern\n"
  mkdir ${SKIN_DIR}/Modern
  git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/Modern Modern
  rm -Rf ${SKIN_DIR}/Modern/.git
  echo "wfLoadSkin( 'Modern' );" >> ${TOP_DIR}/volumes/full/content/${TARGET}/DanteSkinsInstalled.php
  printf "DONE installing skin Modern\n\n"

  # Refreshed
  printf "*** Installing skin Refreshed"
  mkdir ${SKIN_DIR}/Refreshed
  git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/Refreshed Refreshed
  rm -Rf ${SKIN_DIR}/Refreshed/.git
  echo "wfLoadSkin( 'Refreshed' );" >> ${TOP_DIR}/volumes/full/content/${TARGET}/DanteSkinsInstalled.php

  # Chameleon          skin is broken
  # CologneBlue        uses a method which is deprecated in 1.39
}


function getDanteWikiVolume() {

  local BRANCH=master

  printf "*** wget branch ${BRANCH} from dante-wiki-volume ...\n"
    rm -f ${DIR}/volumes/full/content/${BRANCH}.zip
    wget https://github.com/clecap/dante-wiki-volume/archive/refs/heads/${BRANCH}.zip -O ${DIR}/volumes/full/content/${BRANCH}.zip
    unzip -o ${DIR}/volumes/full/content/${BRANCH}.zip -d ${DIR}/volumes/full/content > unzip.log
    rm -f  ${DIR}/volumes/full/content/${BRANCH}.zip 
    mv ${DIR}/volumes/full/content/dante-wiki-volume-${BRANCH}/wiki-dir ${DIR}/volumes/full/content/
    rmdir ${DIR}/volumes/full/content/dante-wiki-volume-${BRANCH}/
  printf "DONE building template directory\n\n"
}


initialTemplates () { # imports an initial set of Parsifal templates from the wiki_dir into a running wiki
  # get directory where this script resides wherever it is called from
  MOUNT=/var/www/html/
  TARGET=wiki-dir
  LAP_CONTAINER=my-lap-container
  printf "*** Importing initial set of Parsifal templates..."
    docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/importTextFiles.php --prefix "MediaWiki:ParsifalTemplate/" --rc --overwrite ${MOUNT}${TARGET}/extensions/Parsifal/initial-templates/*
  printf "DONE\n\n"
}  


copyInMinimal () { # copy in minimal initial contents from here to template volume
  local TARGET=$1
  printf "\n*** Copying in minimal initial contents"
    mkdir -p ${TOP_DIR}/volumes/full/content/${TARGET}/assets

#    cp ${TOP_DIR}/assets/initial-contents/minimal-initial-contents.xml  ${TOP_DIR}/volumes/full/content/${TARGET}/assets/minimal-initial-contents.xml
#    cp "${TOP_DIR}/assets/initial-contents/Main Page" "${TOP_DIR}/volumes/full/content/${TARGET}/assets/Main Page"
#    cp "${TOP_DIR}/assets/initial-contents/Privacypage" "${TOP_DIR}/volumes/full/content/${TARGET}/assets/Privacypage"
#    cp "${TOP_DIR}/assets/initial-contents/Disclaimerpage" "${TOP_DIR}/volumes/full/content/${TARGET}/assets/Disclaimerpage"
#    cp "${TOP_DIR}/assets/initial-contents/Sidebar" "${TOP_DIR}/volumes/full/content/${TARGET}/assets/Sidebar"

    cp "${TOP_DIR}/assets/initial-contents/*" "${TOP_DIR}/volumes/full/content/${TARGET}/assets/"


  printf "DONE copying in minimal initial contents\n\n"
}



minimalInitialContents () {
  MOUNT="/var/www/html/"
  LAP_CONTAINER=my-lap-container
  TARGET=wiki-dir

  CONT=${MOUNT}/${TARGET}/assets/minimal-initial-contents.xml
#   docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/importTextFiles.php --prefix "MediaWiki:ParsifalTemplate/" --rc --overwrite ${MOUNT}${TARGET}/extensions/Parsifal/initial-templates/*

  printf "Initial contents is at $CONT"

  docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/importDump.php --namespaces '8' --debug $CONT
  docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/importDump.php --namespaces '10' --debug $CONT 
  docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/importDump.php --uploads --debug $CONT  

  docker exec ${LAP_CONTAINER} php /var/www/html/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite --prefix "MediaWiki:" ${MOUNT}/${TARGET}/assets/Sidebar

  docker exec ${LAP_CONTAINER} php /var/www/html/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite  "${MOUNT}/${TARGET}/assets/Main Page"

# DO THIS as part of the initial minimal content dump
#  docker exec ${LAP_CONTAINER} php /var/www/html/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite --prefix "MediaWiki" "${MOUNT}/${TARGET}/assets/Disclaimerpage"
#  docker exec ${LAP_CONTAINER} php /var/www/html/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite --prefix "MediaWiki" "${MOUNT}/${TARGET}/assets/Privacypage"
#  docker exec ${LAP_CONTAINER} php /var/www/html/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite --prefix "MediaWiki:Sidebar/" "${MOUNT}/${TARGET}/assets/Areas"
#  docker exec ${LAP_CONTAINER} php /var/www/html/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite --prefix "MediaWiki:Sidebar/" "${MOUNT}/${TARGET}/assets/UI"
#  docker exec ${LAP_CONTAINER} php /var/www/html/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite --prefix "MediaWiki:Sidebar/" "${MOUNT}/${TARGET}/assets/Social"

  printf "\n\n* rebuildrecentchanges\n"
    docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/rebuildrecentchanges.php
  printf "DONE\n"


  docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/initSiteStats.php --update
  docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/rebuildImages.php

  printf "\n\n**** RUNNING: rebuildImages \n"
    docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/rebuildall.php 
  printf "DONE\n"

  printf "\n\n**** RUNNING: checkImages \n"
    docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/checkImages.php
  printf "DONE\n"

  printf "\n\n**** RUNNINF: refreshFileHeaders \n"
    docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/refreshFileHeaders.php --verbose
  printf "DONE\n"


 
}




touchLocalSettings () { # touch the file LocalSettings.php helps refresh the cache
  MOUNT=/var/www/html/
  TARGET=wiki-dir
  printf "*** Touching LocalSettings.php..."
  docker exec ${LAP_CONTAINER} /bin/sh -c "touch ${MOUNT}${TARGET}/LocalSettings.php"
  printf "DONE\n\n"
}


addingImages () {
# Call with name of TARGET, example:  wiki-dir
  TARGET=$1
  printf "\n*** Adding image assets to target=${TARGET}\n"
  cp ${TOP_DIR}/assets/favicon.ico              ${TOP_DIR}/volumes/full/content/${TARGET}/favicon.ico
  cp ${TOP_DIR}/assets/caravaggio-180x180.png   ${TOP_DIR}/volumes/full/content/${TARGET}/logo.png
  printf "\nDONE adding some images\n"
}

installingDrawio () {
# Call with name of TARGET, example: wiki-dir
  TARGET=$1
  printf "\n *** Installing drawio external service into target=${TARGET}\n"
  mkdir -p ${TOP_DIR}/volumes/full/content/${TARGET}/external-services/draw-io/
#  ls ${TOP_DIR}/volumes/full/content/${TARGET}
  wget https://github.com/clecap/drawio/archive/refs/heads/dev.zip -O ${TOP_DIR}/volumes/full/content/${TARGET}/external-services/dev.zip
  unzip -q ${TOP_DIR}/volumes/full/content/${TARGET}/external-services/dev.zip -d ${TOP_DIR}/volumes/full/content/${TARGET}/external-services/draw-io/
  rm ${TOP_DIR}/volumes/full/content/${TARGET}/external-services/dev.zip
  echo "DONE installing drawio external service\n"
}





waitingForDatabase () {
  printf "*** Waiting for database to come up ... \n"
  printf "PLEASE WAIT AT LEAST 1 MINUTE UNTIL NO ERRORS ARE SHOWING UP ANY LONGER\n\n"
  while ! docker exec ${MYSQL_CONTAINER} mysql --user=root --password=${MYSQL_ROOT_PASSWORD} -e "SELECT 1"; do
    sleep 2
    echo "   Still waiting for database to come up..."
  done
  printf "DONE: database container is up\n\n"
}






function dropDatabase () { #  dropDatabase  DB_NAME  DB_CONTAINER  MYSQL_ROOT_PASSWORD
# drops a database. could be helpful before an addDatabase
  local MY_DB_NAME=$1
  local DB_CONTAINER=$2
  local MYSQL_ROOT_PASSWORD=$3
  
  printf "\n\n*** dropDatabase: Dropping database ${MY_DB_NAME} in container ${DB_CONTAINER} \n"

  docker exec -i ${DB_CONTAINER} mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<MYSQLSTUFF
DROP DATABASE IF EXISTS ${MY_DB_NAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;
MYSQLSTUFF

  EXIT_CODE=$?
  printf "DONE: Exit code of dropDatabase generated database call: ${EXIT_CODE} \n\n"
}



function dropUser () {
  local DB_CONTAINER=$1
  local MYSQL_ROOT_PASSWORD=$2
  local MY_DB_USER=$3

  printf "\n\n*** dropUser: Dropping DB users we do not need and listing users of DB \n\n"

  # CAVE: we also must drop MY_DB_USER as we might have created this user earlier and then with a different password
  docker exec -i ${DB_CONTAINER} mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<MYSQLSTUFF
DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ""@"${DB_CONTAINER}";
DROP USER IF EXISTS "${MY_DB_USER}"@"172.16.0.0/255.240.0.0";
DROP USER IF EXISTS "${MY_DB_USER}"@"192.168.0.0/255.255.0.0";
SELECT user, host, password from mysql.user;
MYSQLSTUFF

  EXIT_CODE=$?
  printf "\nDONE: Exit code of dropUser call: ${EXIT_CODE} \n\n"
}




function addDatabase () { ##        addDatabase  DATABASE_NAME  DB_USER_NAME  DB_USER_PASSWORD  MYSQL_ROOT_PASSWORD  DB_CONTAINER
  local MY_DB_NAME=$1
  local MY_DB_USER=$2
  local MY_DB_PASS=$3
  local MYSQL_ROOT_PASSWORD=$4
  local DB_CONTAINER=$5
 
  printf "\n*** addDatabase: Making a database ${MY_DB_NAME} with user ${MY_DB_USER} and password ${MY_DB_PASS} in container ${DB_CONTAINER}\n"

# TODO: Adapt the permissions granted to the specific environment and run-time conditions.
# TODO: CURRENTLY We ARE NOT USING A MYSQL_ROOT_PASSWORD (the empty passowrd works !!!)


# 172.16.0.0/255.240.0.0 is the IP range which is used for the docker bridge and which is most likely the IP address
#   which mysql is likely to see in a login attempt


  docker exec -i ${DB_CONTAINER} mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<MYSQLSTUFF
CREATE DATABASE IF NOT EXISTS ${MY_DB_NAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;
--CREATE USER IF NOT EXISTS ${MY_DB_USER}@'%' IDENTIFIED BY '${MY_DB_PASS}';
--CREATE USER IF NOT EXISTS ${MY_DB_USER}@localhost IDENTIFIED BY '${MY_DB_PASS}';
CREATE USER IF NOT EXISTS ${MY_DB_USER}@'172.16.0.0/255.240.0.0' IDENTIFIED BY '${MY_DB_PASS}';
CREATE USER IF NOT EXISTS ${MY_DB_USER}@'192.168.0.0/255.255.0.0' IDENTIFIED BY '${MY_DB_PASS}';
--GRANT ALL PRIVILEGES ON ${MY_DB_NAME}.* TO '${MY_DB_USER}'@'%';
--GRANT ALL PRIVILEGES ON ${MY_DB_NAME}.* TO '${MY_DB_USER}'@'localhost';
GRANT ALL PRIVILEGES ON ${MY_DB_NAME}.* TO '${MY_DB_USER}'@'172.16.0.0/255.240.0.0';
GRANT ALL PRIVILEGES ON ${MY_DB_NAME}.* TO '${MY_DB_USER}'@'192.168.0.0/255.255.0.0';
FLUSH PRIVILEGES;
MYSQLSTUFF

EXIT_CODE=$?
printf "DONE: Exit code of addDatabase generated database call: ${EXIT_CODE}\n\n"
}



function pullDockerImages() {
  local DOCKER_TAG=$1
  printf "*** Pulling Docker Images from docker hub, tag ${DOCKER_TAG} "
    docker pull clecap/lap:${DOCKER_TAG}
    docker pull clecap/my-mysql:${DOCKER_TAG}
  printf "DONE pulling docker images\n\n"
}


function retagDockerImages() {
  local DOCKER_TAG=$1
  printf "*** Retagging docker images into local names for install mechanisms ... "
    docker tag clecap/lap:${DOCKER_TAG} lap
    docker tag clecap/my-mysql:${DOCKER_TAG} my-mysql
  printf "DONE\n\n"
}


function injectKeys () {

  # directory where we look for keys
  local KEY_DIR=${TOP_DIR}/../KEYS-AND-CERTIFICATES

  local PRIVATE_KEY="$KEY_DIR/$1.key"
  local PUBLIC_KEY="$KEY_DIR/$1.pem"

  # name of the container into which we should copy this in
  LAP_CONTAINER=my-lap-container

  printf "*** Setting up public key infrastructure, if present\n\n"
    if [ -f $PRIVATE_KEY ]; then
      chmod 400 ${PRIVATE_KEY}
      printf "*** Found a private key at ${PRIVATE_KEY}, copying it in and fixing permissions ... \n" 
      docker cp $PRIVATE_KEY    $LAP_CONTAINER:/etc/ssl/apache2/server.key
      docker exec -it $LAP_CONTAINER   chown root.root /etc/ssl/apache2/server.key
      docker exec -it $LAP_CONTAINER   chmod 400 /etc/ssl/apache2/server.key
      printf "DONE\n\n"
    else
      printf "%b" "\e[1;31m *** ERROR: Found no private key, checked at ${PRIVATE_KEY} *** *** \e[0m"
      exit 1
    fi
    if [ -f $PUBLIC_KEY ]; then
      printf "*** Found a public key at ${PUBLIC_KEY}, copying it in and fixing permissions ... \n" 
      chmod 444 ${PUBLIC_KEY}
      docker cp $PUBLIC_KEY $LAP_CONTAINER:/etc/ssl/apache2/server.pem
      docker exec -it $LAP_CONTAINER   chown root.root /etc/ssl/apache2/server.pem
      docker exec -it $LAP_CONTAINER   chmod 444 /etc/ssl/apache2/server.pem
      printf "DONE\n\n"
    else
      printf "%b" "\e[1;31m *** ERROR: Found no private key, checked at ${PRIVATE_KEY} *** *** \e[0m"
      exit 1
  fi
}





function apacheRestartDocker () {  # restart the apaches
  printf "*** Killing apaches and waiting 10 seconds for processes to settle\n"
    docker exec -it $LAP_CONTAINER  killall httpd
    sleep 10
  printf "DONE\n\n"

  printf "*** Restarting apaches\n"
    docker exec -it $LAP_CONTAINER  httpd
  printf "DONE\n\n"
}

cleanUpVolume () { # Code to clean up this directory
  printf "\n*** Cleaning up volume at ${TOP_DIR} \n\n"
  # git somteimes produces awkward permissions
  if [ -d "${TOP_DIR}/volumes/full/content/${TARGET}.git" ]; then
    chmod -R a+w ${TOP_DIR}/volumes/full/content/${TARGET}/.git
  fi
  printf "Will remove ${TOP_DIR}/volumes/full/content/*  \n"
    rm -Rf ${TOP_DIR}/volumes/full/content/*
  printf "DONE content/*\n"
    rm -Rf ${TOP_DIR}/volumes/full/content/*.git
  printf "DONE content/*.git\n"
    rm -f ${TOP_DIR}/volumes/full/content/.gitignore
  printf "DONE content/.gitignore\n"
  printf "DONE cleaning up\n\n"
  mkdir -p ${TOP_DIR}/volumes/full/content/wiki-dir
}


function removeLocalSettings () {  # removes the LocalSettings.php file, reasonable before a (fresh) install
  local LAP_CONTAINER=$1 
  local MOUNT=$2 
  local VOLUME_PATH=$3

  printf "\n*** removeLocalSettings:\n"
  docker exec ${LAP_CONTAINER} rm -f ${MOUNT}/${VOLUME_PATH}/LocalSettings.php      # remove to have a clean start for install routines, ignore if not existant
  EXIT_CODE=$?
  printf "DONE: Exit code of removeLocalSettings docker exec call: ${EXIT_CODE}\n\n"
}



function fixPermissionsProduction() {
  local TARGET="wiki-dir"
  printf "\n *** Fixing local permissions for production" 
    [ -f  ${TOP_DIR}/CONF.sh] && printf "CONF.sh exists "


    [ -f  ${TOP_DIR}/CONF.sh] && chmod -f 700 ${TOP_DIR}/CONF.sh
    [ -d ${TOP_DIR}/../DANTE-BACKUP ] && chmod -f 700 ${TOP_DIR}/../DANTE-BACKUP

 [ -f ${TOP_DIR}/volumes/full/content/${TARGET}/LocalSettings.php ]     &&  printf "\n\n----------- exists \n\n"
#    [ -f ${TOP_DIR}/volumes/full/content/${TARGET}/LocalSettings.php ]     &&  chmod -f 700 ${TOP_DIR}/volumes/full/content/${TARGET}/LocalSettings.php
#    [ -f ${TOP_DIR}/volumes/full/content/${TARGET}/mediawiki-PRIVATE.php ] && chmod -f 700 ${TOP_DIR}/volumes/full/content/${TARGET}/mediawiki-PRIVATE.php
  printf "DONE fixing local permissions"
}


function fixPermissionsContainer() {
  # 100.101 on alpine installations is apache.www-data
  # This defines the target ownership for all files
  local OWNERSHIP="100.101"
  printf "*** Fixing permissions of files ... \n"
    docker exec -it my-lap-container chown -R ${OWNERSHIP} /var/www/html/wiki-dir
  printf "DONE fixing permissions of files\n\n"
}






runMWInstallScript () {  # runMWInstallScript  MW_SITE_NAME  MW_SITE_SERVER  SITE_ACRONYM  WK_PASS
  #    run the mediawiki install script and generate a LocalSettings.php

  printf "*** runMWInstallScript called with $# positional parameters \n\n"

  local MW_SITE_NAME=$1
  local MW_SITE_SERVER=$2
  local SITE_ACRONYM=$3
  local WK_PASS=$4

   printf "*** runMWInstallScript parsed the parameters as follows: MW_SITE_NAME= (${MW_SITE_NAME}) MW_SITE_SERVER=(${MW_SITE_SERVER}) SITE_ACRONYM=(${SITE_ACRONYM}) WK_PASS=(${WK_PASS})\n\n"

  local WK_USER="Admin"

  MEDIAWIKI_DB_HOST=my-mysql
  MEDIAWIKI_DB_TYPE=mysql
  MEDIAWIKI_DB_NAME=${DB_NAME}
  MEDIAWIKI_DB_PORT=3306
  MEDIAWIKI_DB_USER=${DB_USER}
  MEDIAWIKI_DB_PASSWORD=${DB_PASS}
  MEDIAWIKI_RUN_UPDATE_SCRIPT=true

  MEDIAWIKI_SITE_NAME=${MW_SITE_NAME}
  # MEDIAWIKI_SITE_SERVER="https://${LAP_CONTAINER}"
  # TODO: problem: LAP_CONTAINER name is not resolved in the docker host
################################################################# TODO: ADJUST 
######
###### This should rather be a name, maybe localhost TODO: because other wise the different https things do not match
######
#  MEDIAWIKI_SITE_SERVER="https://localhost"
  MEDIAWIKI_SITE_SERVER=${MW_SITE_SERVER}
  MEDIAWIKI_SCRIPT_PATH="/${VOLUME_PATH}"
  # TODO: make language variable inputable into script
  MEDIAWIKI_SITE_LANG=en
  MEDIAWIKI_ADMIN_USER=${WK_USER}
  MEDIAWIKI_ADMIN_PASS=${WK_PASS}
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
docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} php maintenance/install.php \
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
  echo "_______________________________________"
  echo ""

# check if we succeeded to generate LocalSettings.php
docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER}  [ -f "${MOUNT}/${VOLUME_PATH}/LocalSettings.php" ]
EXIT_VALUE=$?
echo "shell result $EXIT_VALUE"
if [ "$EXIT_VALUE" == "0" ]; then
  printf "\e[1;32m* SUCCESS:  ${MOUNT}/${VOLUME_PATH}/LocalSettings.php  generated \e[0m \n"
else
  printf "\033[0;31m *ERROR:  Could not generate ${MOUNT}/${VOLUME_PATH}/LocalSettings.php - *** ABORTING \033[0m\n"
fi
}
# endregion




#  both gets spec     --db my-test-db-volume --vol ${LAP_VOLUME}
# DB_SPEC  --db my-test-db-volume


function runDB() {
 
  source CONF.sh
  # provides MYSQL_ROOT_PASSWORD
  # provides MYSQL_DUMP_USER
  # provides MYSQL_DUMP_PASSWORD

  local CONTAINER_NAME=my-mysql
  local NETWORK_NAME=dante-network

  local HOST_NAME=${CONTAINER_NAME}

  # username only for ssh mechanism TODO:: still need and have that ???  check docker
  local USERNAME=cap

  local DB_VOLUME_NAME=mysql-volume
  local MOUNT=/var/mysql

  printf " *** creating docker network ${NETWORK_NAME} ..."
    docker network create ${NETWORK_NAME}
  printf "\n DONE creating docker network\n\n"

  printf " *** Creating DB container ${CONTAINER_NAME} "

# export environment variables to the docker container for use there and in the entry point

  ## TODO: do we still want / need that ???
  ## below: provide USERNAME to trigger ssh mechanism
  docker run -d --name ${CONTAINER_NAME}                      \
    --network ${NETWORK_NAME}                                      \
    -h ${HOST_NAME}                                           \
    --env USERNAME=${USERNAME}                                \
    -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}"           \
    -e MYSQL_DUMP_USER="${MYSQL_DUMP_USER}"                   \
    -e MYSQL_DUMP_PASSWORD"${MYSQL_DUMP_PASSWORD}"            \
    --volume ${DB_VOLUME_NAME}:/${MOUNT}                      \
    ${CONTAINER_NAME}                          
}


function runLap() {
  source CONF.sh

  local CONTAINER_NAME=my-lap-container
  local PORT_HTTP=8080
  local PORT_HTTPS=4443
  local IMAGE_NAME=lap
  local HOST_NAME=${CONTAINER_NAME}

  local MOUNT_VOL=/var/www/html
  local VOLUME_NAME=

  local MODE=php
  local NETWORK_NAME=dante-network

  printf " *** Starting ${IMAGE_NAME} as ${CONTAINER_NAME} \n"
    docker run -d --name ${CONTAINER_NAME} \
      -p  ${PORT_HTTP}:80                       \
      -p ${PORT_HTTPS}:443                      \
      --network ${NETWORK_NAME}                     \
      --volume ${VOLUME_NAME}:/${MOUNT_VOL}                     \
      -h ${HOST_NAME}                 \
      --env MODE=${MODE}              \
      ${IMAGE_NAME}
  printf " DONE\n\n"
}









## addingReferenceToDante:  Injects into LocalSettings.php a line loading our own configuration for Dante
# region  addingReferenceToDante MOUNT  VOLUME_PATH  LAP_CONTAINER
addingReferenceToDante () {
  local MOUNT=$1
  local VOLUME_PATH=$2
  local LAP_CONTAINER=$3

  echo ""
  echo "*** Adding reference to DanteSettings.php"

# NOTE: Doing this with include does not produce an error if the file goes missing

  docker exec -w /${MOUNT}/${VOLUME_PATH}   ${LAP_CONTAINER}  sh -c "echo ' ' >> LocalSettings.php"
  docker exec -w /${MOUNT}/${VOLUME_PATH}   ${LAP_CONTAINER}  sh -c "echo '###' >> LocalSettings.php"
  docker exec -w /${MOUNT}/${VOLUME_PATH}   ${LAP_CONTAINER}  sh -c "echo '### Automagically injected by volume cmd.sh ' >> LocalSettings.php"
  docker exec -w /${MOUNT}/${VOLUME_PATH}   ${LAP_CONTAINER}  sh -c "echo '###' >> LocalSettings.php  "
  docker exec -w /${MOUNT}/${VOLUME_PATH}   ${LAP_CONTAINER}  sh -c "echo 'include (\"DanteSettings.php\"); ' >> LocalSettings.php "
  echo "DONE adding a reference to DanteSettings.php"
  echo ""
}
# endregion







makeWikiLocal () {
# makeWikiLocal: Installs mediawiki from local cache directory vendor
##                call as  makeWiki  MAJOR  MINOR  TARGET
##                example:  makeWiki 1.37.0 wiki-dir
  WIKI_VERSION_MAJOR=$1
  WIKI_VERSION_MINOR=$2
  TARGET=$3

  WIKI_NAME=mediawiki-${WIKI_VERSION_MAJOR}.${WIKI_VERSION_MINOR}
  LOCAL_FILE="${DIR}/../../../vendor/mediawiki/${WIKI_NAME}.tar.gz"

  if [ ! -f "$LOCAL_FILE" ]; then
    echo "*** Local cached version is missing, pulling from the network"
    mkdir -p ${DIR}/../../../vendor/mediawiki
    cd ${DIR}/../../../vendor/mediawiki
    wget https://releases.wikimedia.org/mediawiki/${WIKI_VERSION_MAJOR}/${WIKI_NAME}.tar.gz;
    cd ${DIR}
  else 
    echo "*** Found locally cached copy $LOCAL_FILE"
  fi

  cd ${DIR}/../content
  mkdir -p ${TARGET}
  cd ${TARGET}
  echo "*** Unpacking local copy $LOCAL_FILE, please wait..."
  tar --strip-components=1 -xzf ${LOCAL_FILE}
  printf "DONE un-taring of ${LOCAL_FILE}\n\n"

  rm -Rf ${TOP_DIR}/volumes/full/content/${TARGET}/skins/Refreshed/.git

  echo "DONE"
}




# docker exec ${LAP_CONTAINER} rm -f ${MOUNT}/${VOLUME_PATH}/LocalSettings.php      # remove to have a clean start for install routines, ignore if not existant


#  addDatabase ${DB_NAME} ${DB_USER} ${DB_PASS}




