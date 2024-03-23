#!/bin/bash

#
# This is a library of bash script functions
#

SCRIPT_LIB_VERSION=2.51

SECRET_FILE="${TOP_DIR}/private/mysql-root-password.txt"

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



function simpleEntryPage () { #  dynamically generate a simple entry page on the target-less url
  local TARGET=wiki-dir
  echo "<html><head></head><body><a href='${TARGET}/index.php'>To Wiki ${TARGET}</a></body></html>" >>  ${TOP_DIR}/volumes/full/content/index.html
}


function getSkinGerrit () {
  local TARGET=$1
  local SKIN=$2

  local SKIN_DIR=${TOP_DIR}/volumes/full/content/${TARGET}/skins
  cd ${SKIN_DIR}

  # Modern
  printf "*** Installing skin Modern\n"
  mkdir ${SKIN_DIR}/${SKIN}
  git clone -b $MW_VERSION --single-branch https://gerrit.wikimedia.org/r/mediawiki/skins/${SKIN} ${SKIN}
  rm -Rf ${SKIN_DIR}/${SKIN}/.git
  echo "wfLoadSkin( '${SKIN}' );" >> ${TOP_DIR}/volumes/full/content/${TARGET}/DanteSkinsInstalled.php
  printf "DONE installing skin ${SKIN}\n\n"

  # Chameleon          skin is broken
  # CologneBlue        uses a method which is deprecated in 1.39
}




function getDanteWikiVolume() {

  local BRANCH=master

  printf "*** wget branch ${BRANCH} from dante-wiki-volume ...\n\n"
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




function installExtensionGithub () { # INSTALL an extension which is hosted on github
  # EXAMPLE:   installExtensionGithub  https://github.com/kuenzign/WikiMarkdown  WikiMarkdown  main
  local URL=$1
  local NAME=$2
  local BRANCH=$3

  ## ASSUMES the global variables
  # MOUNT
  # VOLUME_PATH
  # LAP_CONTAINER

  printf "\n*** INSTALLING EXTENSION ${NAME} from ${URL} using branch ${BRANCH} ...\n"

  printf " * Ensuring proper git postbuffer size..."
    # https://stackoverflow.com/questions/21277806/fatal-early-eof-fatal-index-pack-failed/29355320#29355320
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "git config --global http.postBuffer 524288000"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "git config --global core.packedGitLimit 512m"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "git config --global core.packedGitWindowSize 512m"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "git config --global pack.deltaCacheSize 2047m"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "git config --global pack.packSizeLimit 2047m"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "git config --global pack.windowMemory 2047m"
  printf " DONE\n"

  printf " * Removing preexisting directory..."
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/ ${LAP_CONTAINER}  sh -c "rm -Rf ${NAME} "
  printf " DONE\n"

  printf "   Cloning ${URL} with branch ${BRANCH} into ${NAME}\n"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions ${LAP_CONTAINER}          sh -c " git clone --depth 1 ${URL} --branch ${BRANCH} ${NAME} "

  printf "   Removing .git to save on space\n"
    docker exec -w /${MOUNT}/${VOLUME_PATH}/extensions/${NAME} ${LAP_CONTAINER}  sh -c "rm -Rf .git "

  printf "   Injecting installation into DanteDynamicInstalls.php\n"
    docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} sh -c "echo \"wfLoadExtension( '${NAME}' );\" >> DanteDynamicInstalls.php "
  printf "*** COMPLETED INSTALLING EXTENSION ${NAME} from ${URL} using branch ${BRANCH}\n\n"
}





copyInMinimal () { # copy in minimal initial contents from here to template volume
  local TARGET=$1
  printf "\n*** Copying in minimal initial contents \n"
    mkdir -p ${TOP_DIR}/volumes/full/content/${TARGET}/assets
    cp ${TOP_DIR}/assets/initial-contents/*  ${TOP_DIR}/volumes/full/content/${TARGET}/assets/
  printf "DONE copying in minimal initial contents\n\n"
}


function minimalInitialContents () { # load the minimal initial content into a freshly initialized dantewiki
  MOUNT="/var/www/html/"
  LAP_CONTAINER=my-lap-container
  TARGET=wiki-dir

  CONT=${MOUNT}/${TARGET}/assets/minimal-initial-contents.xml
#   docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/importTextFiles.php --prefix "MediaWiki:ParsifalTemplate/" --rc --overwrite ${MOUNT}${TARGET}/extensions/Parsifal/initial-templates/*

  printf "Initial contents is at $CONT"

  docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/importDump.php --namespaces '8' --debug $CONT
  docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/importDump.php --namespaces '10' --debug $CONT 
  docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/importDump.php --uploads --debug $CONT  

  # main page and sidebar need a separate check in to be up to date properly
  docker exec ${LAP_CONTAINER} php /var/www/html/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite --prefix "MediaWiki:" ${MOUNT}/${TARGET}/assets/Sidebar
  docker exec ${LAP_CONTAINER} php /var/www/html/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite  "${MOUNT}/${TARGET}/assets/Main Page"

  printf "\n\n**** RUNNING: initSiteStats \n"
    docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/initSiteStats.php --update
  printf "DONE\n"

# Not needed since no images are uploaded
#  printf "\n\n**** RUNNING: initSiteStats \n"
#    docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/rebuildImages.php
#  printf "DONE\n"

  printf "\n\n**** RUNNING: rebuildall \n"
    docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/rebuildall.php 
  printf "DONE\n"

  printf "\n\n**** RUNNING: checkImages \n"
    docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/checkImages.php
  printf "DONE\n"

  printf "\n\n**** RUNNING: refreshFileHeaders \n"
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
  wget --no-verbose -q https://github.com/clecap/drawio/archive/refs/heads/dev.zip -O ${TOP_DIR}/volumes/full/content/${TARGET}/external-services/dev.zip
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

# this rather should be performed by the php script itself, given the mysql root
# only keep it in should we need it later
function addDatabase () { ##        addDatabase  DATABASE_NAME  DB_USER_NAME  DB_USER_PASSWORD  DB_CONTAINER
  local MY_DB_NAME=$1
  local MY_DB_USER=$2
  local MY_DB_PASS=$3
  local DB_CONTAINER=$4

  ensure MY_DB_NAME  MY_DB_USER  MY_DB_PASS  DB_CONTAINER
 
  printf "\n*** addDatabase: Making a database=${MY_DB_NAME} with user=${MY_DB_USER} and password=${MY_DB_PASS} in container=${DB_CONTAINER}\n"

# 172.16.0.0/255.240.0.0 is the IP range which is used for the docker bridge and which is most likely the IP address
#   which mysql is likely to see in a login attempt

  local MYSQL_ROOT_PASSWORD=$(cat "${SECRET_FILE}")

# docker exec -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} -i ${DB_CONTAINER} mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<MYSQLSTUFF
docker exec -i ${DB_CONTAINER} mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<MYSQLSTUFF
CREATE DATABASE IF NOT EXISTS ${MY_DB_NAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;
CREATE USER IF NOT EXISTS ${MY_DB_USER}@'172.16.0.0/255.240.0.0' IDENTIFIED BY '${MY_DB_PASS}';
CREATE USER IF NOT EXISTS ${MY_DB_USER}@'192.168.0.0/255.255.0.0' IDENTIFIED BY '${MY_DB_PASS}';
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
      docker exec $LAP_CONTAINER   chown root.root /etc/ssl/apache2/server.key
      docker exec $LAP_CONTAINER   chmod 400 /etc/ssl/apache2/server.key
      printf "DONE\n\n"
    else
      printf "%b" "\e[1;31m *** ERROR: Found no private key, checked at ${PRIVATE_KEY} *** *** \e[0m"
      exit 1
    fi
    if [ -f $PUBLIC_KEY ]; then
      printf "*** Found a public key at ${PUBLIC_KEY}, copying it in and fixing permissions ... \n" 
      chmod 444 ${PUBLIC_KEY}
      docker cp $PUBLIC_KEY $LAP_CONTAINER:/etc/ssl/apache2/server.pem
      docker exec $LAP_CONTAINER   chown root.root /etc/ssl/apache2/server.pem
      docker exec $LAP_CONTAINER   chmod 444 /etc/ssl/apache2/server.pem
      printf "DONE\n\n"
    else
      printf "%b" "\e[1;31m *** ERROR: Found no private key, checked at ${PRIVATE_KEY} *** *** \e[0m"
      exit 1
  fi
}


function ensure () { # ensures if a list of variables is set; if not, provide suitable error message
  for var_name in "$@"; do
    if [[ -n ${!var_name+x} ]]; then
      true
    else
      printf " *** ERROR: The variable '$var_name' is not set\n\n"
      false
    fi
  done
}


function makeMediawikiPrivate () { # during installation make mediawiki-PRIVATE.php file which is included by DanteSettings.php / LocalSettings.php
  local MWP=${DIR}/conf/mediawiki-PRIVATE.php

  printf "*** Generating mediawiki-PRIVATE configuration file at ${MWP}\n"
    ensure SMTP_SENDER_ADDRESS  SMTP_HOSTNAME  SMTP_PORT  SMTP_USERNAME  SMTP_PASSWORD  LOCALTIMEZONE  

    rm   -f ${MWP}
    touch ${MWP}
    chmod 600 ${MWP}
    echo  "<?php "   >> ${MWP}
    echo "\$wgPasswordSender='${SMTP_SENDER_ADDRESS}';          // address of the sending email account                            " >> ${MWP}
    echo "\$wgSMTP = [                                                                                                             " >> ${MWP}
    echo  "  'host'     => '${SMTP_HOSTNAME}',                 // hostname of the smtp server of the email account  " >> ${MWP}
    echo  "  'IDHost'   => 'localhost',                        // sub(domain) of your wiki                                             " >> ${MWP}
    echo  "  'port'     => ${SMTP_PORT},                       // SMTP port to be used      " >> ${MWP}
    echo  "  'username' => '${SMTP_USERNAME}',                 // username of the email account   " >> ${MWP}
    echo  "  'password' => '${SMTP_PASSWORD}',                 // password of the email account   " >> ${MWP}
    echo  "  'auth'     => true                                // shall authentisation be used    " >> ${MWP}
    echo "]; "                                      >> ${MWP}
    echo "\$wgLocaltimezone='${LOCALTIMEZONE}';"    >> ${MWP}

    echo "\$DEEPL_API_KEY='${DEEPL_API_KEY};'"      >> ${MWP}

    # AWS data for an S3 user restricted to backup   dantebackup.iuk.one
    echo "\$wgDefaultUserOptions['aws-accesskey']       = '${AWS_ACCESSKEY}';"      >> ${MWP}
    echo "\$wgDefaultUserOptions['aws-secretaccesskey'] = '${AWS_SECRETACCESSKEY}';"    >> ${MWP}
    echo "\$wgDefaultUserOptions['aws-bucketname']      =  '${AWS_BUCKETNAME}';"    >> ${MWP}
    echo "\$wgDefaultUserOptions['aws-region']          =  '${AWS_REGION}';"    >> ${MWP}
    echo "\$wgDefaultUserOptions['aws-encpw']           =  '${AWS_ENCPW}';"    >> ${MWP}


    echo "?>  "                                     >> ${MWP}
    cp ${MWP}  ${DIR}/volumes/full/content/wiki-dir
    chmod 700  ${DIR}/volumes/full/content/wiki-dir
    rm ${MWP}
  printf "DONE generating mediawiki-PRIVATE configuration file at ${MWP}\n\n"
}


function apacheRestartDocker () {  # restart the apaches
  printf "*** Killing apaches and waiting 10 seconds for processes to settle\n"
    # below necessary to prevent error status when no process was found
    docker exec $LAP_CONTAINER /bin/ash -c "killall httpd || echo 'No process running' "
    sleep 10
  printf "DONE\n\n"

  printf "*** Restarting apaches\n"
    docker exec $LAP_CONTAINER  httpd
  printf "DONE\n\n"
}

cleanUpVolume () { # Code to clean up this local directory which later shall serve as volume 
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
  printf "\n *** Fixing local permissions for production\n"


  #    [ -f  ${TOP_DIR}/CONF.sh ] && printf "CONF.sh exists\n"


#  chmod -f 700 ${TOP_DIR}/CONF.sh

#    [ -f  ${TOP_DIR}/CONF.sh ] && chmod -f 700 ${TOP_DIR}/CONF.sh
#    [ -d ${TOP_DIR}/../DANTE-BACKUP ] && chmod -f 700 ${TOP_DIR}/../DANTE-BACKUP

#  [ -f ${TOP_DIR}/volumes/full/content/${TARGET}/LocalSettings.php ]     &&  printf "\n\n----------- exists \n\n"
#    [ -f ${TOP_DIR}/volumes/full/content/${TARGET}/LocalSettings.php ]     &&  chmod -f 700 ${TOP_DIR}/volumes/full/content/${TARGET}/LocalSettings.php
#    [ -f ${TOP_DIR}/volumes/full/content/${TARGET}/mediawiki-PRIVATE.php ] && chmod -f 700 ${TOP_DIR}/volumes/full/content/${TARGET}/mediawiki-PRIVATE.php
  printf "DONE fixing local permissions\n\n"
}


# fixes permissions inside of the container, using docker exec
function fixPermissionsContainer() {
  # 100.101 on alpine installations is apache.www-data
  # This defines the target ownership for all files
  local OWNERSHIP="100.101"
  printf "*** Fixing permissions of files ... \n"
    docker exec my-lap-container chown -R ${OWNERSHIP} /var/www/html/wiki-dir
    docker exec my-lap-container chmod 700 /var/www/html/wiki-dir
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

  MEDIAWIKI_SITE_NAME="${MW_SITE_NAME}"
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



function setUserPreferences () {
# assume we have global  MOUNT   VOLUME_PATH   LAP_CONTAINER   set  
  local WK_USER="Admin"

# error of ChatGPT to suggest this
#  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} php maintenance/update.php  --user "${WK_USER}"  --setpref aws-accesskey="One"
#  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} php maintenance/update.php  --user "${WK_USER}"  --setpref aws-secretaccesskey="Two"
#  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} php maintenance/update.php  --user "${WK_USER}"  --setpref aws-bucketname="Three"
#  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} php maintenance/update.php  --user "${WK_USER}"  --setpref aws-region="Four Region"
#  docker exec -w /${MOUNT}/${VOLUME_PATH} ${LAP_CONTAINER} php maintenance/update.php  --user "${WK_USER}"  --setpref aws-encpw="Pass Word"
}

# deprecate this function TODO
function cleanUpDocker () { # cleaning up ressources to have a good fresh start; produces no error when not found
  local CONTAINER=$1
  local VOLUME=$2
  printf "*** Cleaning up existing DANTE ressources"

  printf " ** Attempting to stop container ${CONTAINER}, if it exists \n"
    docker ps -a | grep '${CONTAINER}' && docker container stop  -f '${CONTAINER}' || printf "Container ${CONTAINER} was not found when attempting to stop   \n"
  printf " DONE stopping container ${CONTAINER}\n\n"

  printf " ** Attempting to remove container ${CONTAINER}, if it exists \n"
    docker ps -a | grep '${CONTAINER}' && docker rm -f '${LAP_CONTAINER}'             || printf "Container ${CONTAINER} was not found when attempting to remove \n"
  printf " DONE removing container ${CONTAINER}\n\n"

  docker system prune --force --all

  printf " ** Attempting to volume ${CONTAINER}, if it exists \n"
    docker volume ls | grep '${VOLUME}' && docker volume rm  '${VOLUME}'             || printf "Volume ${VOLUME} was not found when attempting to remove \n"
  printf " DONE removing volume ${VOLUME}\n\n"
}





#  both gets spec     --db my-test-db-volume --vol ${LAP_VOLUME}
# DB_SPEC  --db my-test-db-volume


function runDB() {
 
  # TODO: reprecate this code
  # source CONF.sh
  # provides MYSQL_ROOT_PASSWORD
  # provides MYSQL_DUMP_USER
  # provides MYSQL_DUMP_PASSWORD
  ## TODO remove MYSQL ROOT PASSWORD from CONF.sh everywhere

  local MYSQL_ROOT_PASSWORD=$(cat "${SECRET_FILE}")

  local CONTAINER_NAME=my-mysql
  local NETWORK_NAME=dante-network

  local HOST_NAME=${CONTAINER_NAME}

  # username only for ssh mechanism TODO:: still need and have that ???  check docker
  local USERNAME=cap

  local DB_VOLUME_NAME=mysql-volume
  local MOUNT=/var/mysql

  if ! docker network inspect "$NETWORK_NAME" > /dev/null 2>&1; then
    printf " ** Network $NETWORK_NAME does not exist, creating it\n\n"
      docker network create "$NETWORK_NAME"
    printf " DONE creating it\n\n"
  else
    printf " ** Network $NETWORK_NAME already exists\n\n"
  fi

  if docker container inspect "$CONTAINER_NAME" > /dev/null 2>&1; then
    if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" == "false" ]; then
      printf " *** Container $CONTAINER_NAME exists but is stopped. Starting the container now.\n"
        docker container start "$CONTAINER_NAME"
      printf " DONE starting container $CONTAINER_NAME\n\n"
    else
      printf " *** Container '$CONTAINER_NAME' is already running.\n\n"
    fi
  else
    printf " *** Container '$CONTAINER_NAME' does not exist. Creating and running it\n"
      docker run -d --name ${CONTAINER_NAME}                      \
        --network ${NETWORK_NAME}                                 \
        -h ${HOST_NAME}                                           \
        --env USERNAME=${USERNAME}                                \
        -e MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}"           \
        -e MYSQL_DUMP_USER="${MYSQL_DUMP_USER}"                   \
        -e MYSQL_DUMP_PASSWORD"${MYSQL_DUMP_PASSWORD}"            \
        --volume ${DB_VOLUME_NAME}:/${MOUNT}                      \
        ${CONTAINER_NAME}                          
    printf " DONE \n\n"
  fi

# export environment variables to the docker container for use there and in the entry point
  ## TODO: do we still want / need that ???
  ## below: provide USERNAME to trigger ssh mechanism
}


# new function
function cleanDockerContainer() {
  local CONTAINER=$1

  trap - ERR

  printf " ** Attempting to stop container ${CONTAINER}, if it exists \n"
  docker container stop ${CONTAINER} 
  printf " DONE stopping container ${CONTAINER}\n\n"

  printf " ** Attempting to remove container ${CONTAINER}, if it exists \n"
  docker rm -f ${CONTAINER}
  printf " DONE removing container ${CONTAINER}\n\n"

  trap 'handle_error $LINENO ${BASH_LINENO[@]} $BASH_COMMAND' ERR
}


function volumeExists {
  #  trick used from https://sidshome.wordpress.com/2021/12/17/how-to-check-in-bash-script-if-a-docker-volume-does-not-exist/
  if [ "$(docker volume ls -f name=$1 | awk '{print $NF}' | grep -E '^'$1'$')" ]; then
    return 0
  else
    return 1
  fi
}

# new function
function cleanDockerVolume() {
  local VOLUME=$1
  if volumeExists ${VOLUME}; then
    docker volume rm ${VOLUME}
  else
    printf " DONE. Volume ${VOLUME} did not exist any more "
  fi
  printf " DONE removing volume ${VOLUME}\n\n"
}


function runLap() { # runs the lap container  
  # Parameter 1:    string value:  https or http
  # Parameter 2:    port number under which the service is exposed at the host computer running the service

  printf " *** runLap: called with $1 $2 \n"

  local SERVICE=$1
  local PORT=$2

  local PORT_SPEC=""

  if [ "$SERVICE" = "https" ]; then
    PORTSPEC=" -p ${PORT}:443 "
  else
    if [ "$SERVICE" = "http" ]; then
      PORTSPEC=" -p ${PORT}:80 "
    else
      printf "\e[1;31m***\n*** ERROR at runLap: Incorrect service specification, must be http or https, is ${SERVICE}\n\n"
      return 1
    fi
  fi

  local CONTAINER_NAME=my-lap-container
  local IMAGE_NAME=lap
  local HOST_NAME=${CONTAINER_NAME}

  local MOUNT_VOL=/var/www/html
  local VOLUME_NAME=lap-volume

  local MODE=PHP
  local NETWORK_NAME=dante-network

  printf " *** runLap: Starting image ${IMAGE_NAME} as container ${CONTAINER_NAME} \n"
  printf " *** runLap: Port specification is: ${PORTSPEC} \n "

  if docker container inspect "$CONTAINER_NAME" > /dev/null 2>&1; then
    if [ "$(docker container inspect -f '{{.State.Running}}' "$CONTAINER_NAME")" == "false" ]; then
      printf " *** runLap: Container $CONTAINER_NAME exists but is stopped. Starting the container now.\n"
        docker container start "$CONTAINER_NAME"
      printf " DONE starting container $CONTAINER_NAME\n\n"
    else
      printf " *** runLap: Container '$CONTAINER_NAME' is already running.\n\n"
    fi
  else
    printf " *** runLap: Container '$CONTAINER_NAME' does not exist. Creating and running it\n"
      docker run -d --name ${CONTAINER_NAME}      \
        ${PORTSPEC}                               \
        --network ${NETWORK_NAME}                 \
        --volume ${VOLUME_NAME}:/${MOUNT_VOL}     \
        -h ${HOST_NAME}                           \
        --env MODE=${MODE}                        \
        ${IMAGE_NAME}
    printf " DONE\n\n"
  fi

  printf " DONE runLap \n\n"
}



function addingReferenceToDante () {  # addingReferenceToDante MOUNT  VOLUME_PATH  LAP_CONTAINER
  # Injects into LocalSettings.php a line loading our own configuration for Dante
  local MOUNT=$1
  local VOLUME_PATH=$2
  local LAP_CONTAINER=$3

  printf "*** Adding reference to DanteSettings.php ... "
    docker exec -w /${MOUNT}/${VOLUME_PATH}   ${LAP_CONTAINER}  sh -c "echo ' ' >> LocalSettings.php"
    docker exec -w /${MOUNT}/${VOLUME_PATH}   ${LAP_CONTAINER}  sh -c "echo '###' >> LocalSettings.php"
    docker exec -w /${MOUNT}/${VOLUME_PATH}   ${LAP_CONTAINER}  sh -c "echo '### Automagically injected by volume cmd.sh ' >> LocalSettings.php"
    docker exec -w /${MOUNT}/${VOLUME_PATH}   ${LAP_CONTAINER}  sh -c "echo '###' >> LocalSettings.php  "
    # NOTE: Doing this with include does not produce an error if the file goes missing
    docker exec -w /${MOUNT}/${VOLUME_PATH}   ${LAP_CONTAINER}  sh -c "echo 'include (\"DanteSettings.php\"); ' >> LocalSettings.php "
  printf  "DONE\n\n"
}







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
