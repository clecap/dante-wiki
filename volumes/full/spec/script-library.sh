#!/bin/bash

#
# This is a library of bash script functions
#

# region dropDatabase  DB_NAME  DB_CONTAINER  MYSQL_ROOT_PASSWORD
# drops a database. could be helpful before an addDatabase
dropDatabase () {
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

  local MW_SITE_NAME=$1
  local MW_SITE_SERVER=$2
  local SITE_ACRONYM=$3
  local WK_PASS=$4

  echo ""; echo "*** Running runMWInstallScript on ${MW_SITE_NAME} ${MW_SITE_SERVER} ${SITE_ACRONYM} ${WK_PASS}"

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
  printf "\e[1;31m* SUCCESS:  ${MOUNT}/${VOLUME_PATH}/LocalSettings.php  generated \e[0m"
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









# docker exec ${LAP_CONTAINER} rm -f ${MOUNT}/${VOLUME_PATH}/LocalSettings.php      # remove to have a clean start for install routines, ignore if not existant


#  addDatabase ${DB_NAME} ${DB_USER} ${DB_PASS}




