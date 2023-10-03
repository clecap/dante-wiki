#!/bin/bash

#
# This is a library of bash script functions
#





initialTemplates () { # imports an initial set of Parsifal templates from the wiki_dir into a running wiki
  # get directory where this script resides wherever it is called from
  MOUNT=/var/www/html/
  TARGET=wiki-dir
  LAP_CONTAINER=my-lap-container
  printf "*** Importing initial set of Parsifal templates..."
    set -e; trap 'abort' EXIT                       # call abort on EXIT
    docker exec ${LAP_CONTAINER} php ${MOUNT}${TARGET}/maintenance/importTextFiles.php --prefix "MediaWiki:ParsifalTemplate/" --rc --overwrite ${MOUNT}${TARGET}/extensions/Parsifal/initial-templates/*
  printf "DONE\n\n"

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
  cp ${TOPDIR}/assets/favicon.ico              ${TOPDIR}/volumes/full/content/${TARGET}/favicon.ico
  cp ${TOPDIR}/assets/caravaggio-180x180.png   ${TOPDIR}/volumes/full/content/${TARGET}/logo.png
  printf "\nDONE adding some images\n"
}

installingDrawio () {
# Call with name of TARGET, example: wiki-dir
  TARGET=$1
  printf "\n *** Installing drawio external service into target=${TARGET}\n"
  mkdir -p ${TOPDIR}/volumes/full/content/${TARGET}/external-services/draw-io/
#  ls ${TOPDIR}/volumes/full/content/${TARGET}
  wget https://github.com/clecap/drawio/archive/refs/heads/dev.zip -O ${TOPDIR}/volumes/full/content/${TARGET}/external-services/dev.zip
  unzip -q ${TOPDIR}/volumes/full/content/${TARGET}/external-services/dev.zip -d ${TOPDIR}/volumes/full/content/${TARGET}/external-services/draw-io/
  rm ${TOPDIR}/volumes/full/content/${TARGET}/external-services/dev.zip
  echo "DONE installing drawio external service\n"
}





dropDatabase () {
# region dropDatabase  DB_NAME  DB_CONTAINER  MYSQL_ROOT_PASSWORD
# drops a database. could be helpful before an addDatabase
  local MY_DB_NAME=$1
  local DB_CONTAINER=$2
  local MYSQL_ROOT_PASSWORD=$3
  
  printf "\n\n*** dropDatabase: Dropping database ${MY_DB_NAME} \n"

  docker exec -i ${DB_CONTAINER} mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<MYSQLSTUFF
DROP DATABASE IF EXISTS ${MY_DB_NAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;
MYSQLSTUFF

  EXIT_CODE=$?
  printf "DONE: Exit code of dropDatabase generated database call: ${EXIT_CODE} \n\n"
}
#endregion


dropUser () {
  local DB_CONTAINER=$1
  local MYSQL_ROOT_PASSWORD=$2
  local MY_DB_USER=$3

  printf "\n\n*** dropUser: Dropping default anonymous user \n"


  # CAVE: we also must drop MY_DB_USER as we might have created this user earlier and then with a different password
  docker exec -i ${DB_CONTAINER} mysql -u root --password=${MYSQL_ROOT_PASSWORD} <<MYSQLSTUFF
DROP USER IF EXISTS ''@'localhost';
DROP USER IF EXISTS ""@"${DB_CONTAINER}";
DROP USER IF EXISTS "${MY_DB_USER}"@"172.16.0.0/255.240.0.0";
DROP USER IF EXISTS "${MY_DB_USER}"@"192.168.0.0/255.255.0.0";
SELECT user, host, password from mysql.user;
MYSQLSTUFF

  EXIT_CODE=$?
  printf "DONE: Exit code of dropUser call: ${EXIT_CODE} \n\n"
}


# region  addDatabase:  add a username and a database to the database engine
##        addDatabase  DATABASE_NAME  DB_USER_NAME  DB_USER_PASSWORD  MYSQL_ROOT_PASSWORD  DB_CONTAINER
addDatabase () {
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
# endregion






# region removeLocalSettings
#
# removes the LocalSettings.php file, reasonable before a (fresh) install
removeLocalSettings () {
  local LAP_CONTAINER=$1 
  local MOUNT=$2 
  local VOLUME_PATH=$3

  printf "\n*** removeLocalSettings:\n"
  docker exec ${LAP_CONTAINER} rm -f ${MOUNT}/${VOLUME_PATH}/LocalSettings.php      # remove to have a clean start for install routines, ignore if not existant
  EXIT_CODE=$?
  printf "DONE: Exit code of removeLocalSettings docker exec call: ${EXIT_CODE}\n"
}







# region runMWInstallScript ()   run the mediawiki install script and generate a LocalSettings.php
# runMWInstallScript  MW_SITE_NAME  MW_SITE_SERVER  SITE_ACRONYM  WK_PASS
runMWInstallScript () {

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

  rm -Rf ${TOPDIR}/volumes/full/content/${TARGET}/skins/Refreshed/.git

  echo "DONE"
}




# docker exec ${LAP_CONTAINER} rm -f ${MOUNT}/${VOLUME_PATH}/LocalSettings.php      # remove to have a clean start for install routines, ignore if not existant


#  addDatabase ${DB_NAME} ${DB_USER} ${DB_PASS}




