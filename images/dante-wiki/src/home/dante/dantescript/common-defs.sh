#!/bin/bash

# Common environment variables and definitions for all dantescript scripts


# the remote repository for dante-delta
REMOTE_REPO_DANTE=https://github.com/clecap/dante-delta.git


##
## Conventions we use
##

# mountpoint for the volume
export MOUNT=/var/www/html/

# point in ${MOUNT} where the dante wiki attaches
export TARGET=wiki-dir

# directory where to pick up the minimal initial contents
export CONT=/home/dante/initial-contents/generic 

##
## codes for printf
##
export RESET="\e[0m"
export ERROR="\e[1;31m"

# 32m for green
# 92m for bold green
export GREEN="\e[1;32m"




# report an error and abort the calling script with a non-zero exit status, so that the caller sees the failure
# usage:   some-command || failed "description of what went wrong"
failed()
{
  printf "\n${ERROR}*** $(basename "$0") ERROR: $1 - ABORTING${RESET}\n"
  exit 1
}



bannerGreen()
{
 if [ $# -eq 0 ]; then
    printf "\n\n${GREEN} *** *** *** ****** *** *** *** ${RESET}\n"; 
    printf     "${GREEN} *** *** *** ****** *** *** *** ${RESET}\n"; 
  else
    local input="$1"
    printf "\n\n${GREEN} *** *** *** ****** *** *** *** ${RESET}\n"; 
    printf     "${GREEN} *** *** *** ****** *** *** *** ${RESET}\n"; 
    printf     "${GREEN} ***  ${input^^}  ${RESET}\n";
    printf     "${GREEN} *** *** *** ****** *** *** *** ${RESET}\n"; 
    printf     "${GREEN} *** *** *** ****** *** *** *** ${RESET}\n\n"; 
  fi
}





installInitialFromGit()
{
  local PREFIX="https://raw.githubusercontent.com/clecap/dante-wiki-contents/master/assets/initial-contents/"
  local url=${PREFIX}$1.xml.gz
  printf "${GREEN}*** Checking in contents from $url ...${RESET}"
  
  curl -L $url | gunzip -c | php ${MOUNT}${TARGET}/maintenance/importDump.php --namespaces '8'
  curl -L $url | gunzip -c | php ${MOUNT}${TARGET}/maintenance/importDump.php --namespaces '10'
  curl -L $url | gunzip -c | php ${MOUNT}${TARGET}/maintenance/importDump.php --uploads
  printf "\n${GREEN}COMPLETED${RESET}\n\n"
}

downloadInitialGitToLocal()
{
  local PREFIX="https://raw.githubusercontent.com/clecap/dante-wiki-contents/master/assets/initial-contents/"
  local url=${PREFIX}$1.xml.gz
  printf "${GREEN}*** Checking in contents from $url to /tmp ...${RESET}"
  curl -L $url --output /tmp/${url}
  printf "\n${GREEN}COMPLETED${RESET}\n\n"
}

installInitialFromLocal()
{
  local PREFIX="/tmp/"
  local url=${PREFIX}$1.xml.gz
  printf "${GREEN}*** Checking in contents from $file ...${RESET}"
  cat $file | gunzip -c | php ${MOUNT}${TARGET}/maintenance/importDump.php --namespaces '8'
  cat $file | gunzip -c | php ${MOUNT}${TARGET}/maintenance/importDump.php --namespaces '10'
  cat $file | gunzip -c | php ${MOUNT}${TARGET}/maintenance/importDump.php --uploads
  printf "\n${GREEN}COMPLETED${RESET}\n\n"
}


# print $1 as a PHP single-quoted string literal: escape \ and ' so that any value (e.g. a password) is safe
# usage inside a heredoc:   'password' => $(phpQuote "${SMTP_PASSWORD}"),
phpQuote()
{
  local s=${1//\\/\\\\}
  s=${s//\'/\\\'}
  printf "'%s'" "$s"
}


# print $1 as an SQL single-quoted string literal for MariaDB / MySQL
# The escaping is the same as for PHP (\ and '), as long as sql_mode does not contain NO_BACKSLASH_ESCAPES (default)
# usage inside a heredoc:   INSERT INTO t (c) VALUES ($(sqlQuote "${VALUE}"));
sqlQuote()
{
  phpQuote "$1"
}


## Load the secret configuration file
loadSecrets()
{
  if [ -f "/run/secrets/configuration" ]; then
    printf "$GREEN*** common-defs.sh:loadSecrets will now load configuration...${RESET} \n"
    source /run/secrets/configuration ; exec 1>&1 2>&2
    export DANTE_CONFIG_HASH=$(shasum -a 256 /run/secrets/configuration | awk '{ print $1 }')
    printf "DONE loading configuration ${DANTE_CONFIGURATION_NAME}, hashed to ${DANTE_CONFIG_HASH}\n"
    # refuse to continue with empty database credentials
    ##### TODO: add such checks for the other user and password variables as well 
    local VAR
    for VAR in MY_DB_HOST MY_DB_NAME MY_DB_USER MY_DB_PASS MY_DB_I_USER MY_DB_I_PASS; do
      [ -n "${!VAR}" ] || { printf "${ERROR}*** common-defs.sh:loadSecrets: ${VAR} is empty or not set in configuration - EXITING${RESET}\n"; exit 1; }
    done
  else
    printf "$ERROR*** common-defs.sh:loadSecrets could not find configuration file, EXITING $RESET\n"
    exit 1
  fi
}








# Function to check if the database server $1 is running
# returns 0 (true) if it is running, 1 (false) otherwise
#### TODO  MAYBE this is already deprecated ????
#### CAVE: NEEDS correct password !!!
ping_dbserver() {
  local MY_DB_HOST="$1"
  printf "ping_dbserver_running: Pinging database $MY_DB_HOST \n"
  mysqladmin ping -h "$MY_DB_HOST" 


  sleep 600000

  RESULT=$?
  printf "mysqladmin returned $RESULT"
  if [ $RESULT -eq 0 ]; then
    printf "ping_dbserver: Returning true\n"
    return 0      # true
  else
    printf "ping_dbserver: Returning false\n"
    return 1      # false
  fi
}



# check if the database server $1 is reachable on its port
# returns 0 (true) if it is reachable, 1 (false) otherwise
check_dbserver_running() {
  local MYSQL_HOST="$1"
  local MYSQL_PORT=3306

# Use /dev/tcp to check if the MySQL server is reachable
  if (echo > /dev/tcp/$MYSQL_HOST/$MYSQL_PORT) &> /dev/null; then
    printf "   check_dbserver_running: MySQL server ${MYSQL_HOST} is up\n"
    return 0      # true
  else
    printf "   check_dbserver_running: MySQL server ${MYSQL_HOST} is down or unreachable\n"
    return 1      # false
  fi
}




# wait sleeping until DB server $1 is running
# returns 0 (true) once it is running; exits the calling script with 1 if it does not come up
wait_dbserver_running() {
  local MY_DB_HOST="$1"
  local MAX_RETRIES=100
  local SLEEP_INTERVAL=5
  local RETRY_COUNT=0

  printf "\n$GREEN*** This is wait_dbserver_running: we are waiting for $MY_DB_HOST to come up${RESET}\n"
  while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    if check_dbserver_running "$MY_DB_HOST"; then     # branch taken when the function returned true
      printf "$GREEN*** wait_dbserver_running: SUCCESS: Database server is running, exiting script at retrycount=$RETRY_COUNT\n ${RESET}"
      return 0      # true
    else
      printf "   wait_dbserver_running: Database server does not exist. Will sleep ${SLEEP_INTERVAL} seconds and then retry. We are at retry count $RETRY_COUNT\n"
      sleep $SLEEP_INTERVAL
      ((RETRY_COUNT++))
    fi
  done
  printf "\n\n $ERROR*** wait_dbserver_running: ERROR: Database server not running after ${MAX_RETRIES} retries.\n\n${RESET}"
  sleep 600000
  exit 1
}


# check if the database server $1 still accepts the initial root password
# returns 0 (true) if it does, 1 (false) if the server is not reachable or the password has already been changed
check_dbserver_initial_rootpassword() {
  local MY_DB_HOST="$1"  # TODO This should perhaps also be picked up from configuration
  local MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"
  printf "\n${GREEN}*** check_dbserver_initial_password: Checking DB for initial root password on MY_DB_HOST=${MY_DB_HOST}...\n"
  ### printf "   Current environment variable MYSQL_PWD has value: ${MYSQL_PWD}\n"  ## ONLY USE FOR DEBUGGING since this would leak the password into the log
  local OUTPUT=$(mysqladmin ping -u root -pinitialPassword -h "$MY_DB_HOST" --skip-ssl 2>&1)
  printf "    Output of the ping was: ${OUTPUT}\n"
  if echo "$OUTPUT" | grep -i -q "ERROR"; then
      printf "${ERROR}***check_dbserver_initial_password: db server is not running or initial password is incorrect.\n"
      return 1      # false
    else
      printf "${GREEN}    check_dbserver_initial_password: db server is running and initial password is ok.\n"
      return 0      # true
  fi
}


# Function to check if the database $1 exists and is running
# returns 0 (true) if it exists, 1 (false) otherwise
# assumes MYSQL_PWD contains the root password
check_database_exists() {
  printf "$GREEN***Checking if database $1 exists...\n"
  local DB_NAME="$1"
  local RESULT=$(mysql -h $MY_DB_HOST -u root -e "SHOW DATABASES LIKE '${DB_NAME}';" --skip-ssl 2>&1)
  printf "Result of query was: ${RESULT}\n"
  if [[ "$RESULT" == *"$DB_NAME"* ]]; then
      printf "check_database_exists found database ${DB_NAME}"
      return 0      # true
    else
      printf "check_database_exists did not find database ${DB_NAME}"
      return 1      # false
  fi
}


# check if database server $1 has a database named $2
# returns 0 (true) if the database exists, 1 (false) if it does not exist or the query failed
# assumes MYSQL_PWD contains the root password
check_dbserver_has_database() {
  local MY_DB_HOST="$1"
  local DB_NAME="$2"
  local COUNT

  COUNT=$(mysql -h "${MY_DB_HOST}" -u root --skip-ssl -N -s -e \
    "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = $(sqlQuote "${DB_NAME}");")
  if [ "${COUNT}" = "1" ]; then
    printf "   check_dbserver_has_database: database ${DB_NAME} exists on ${MY_DB_HOST}\n"
    return 0      # true
  else
    printf "   check_dbserver_has_database: database ${DB_NAME} not found on ${MY_DB_HOST}\n"
    return 1      # false
  fi
}



# wait sleeping until database $1 exists
# returns 0 (true) once it exists; exits the calling script with 1 if it does not show up
wait_database_ready() {
  local DB_NAME="$1"
  local MAX_RETRIES=100
  local SLEEP_INTERVAL=5
  local RETRY_COUNT=0
  printf "\n$GREEN*** wait_database_ready: Waiting for $MY_DB_HOST to come up with ${DB_NAME}\n${RESET}"
  while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    if check_database_exists "${DB_NAME}"; then     # branch taken when the function returned true
        printf "$GREEN*** wait_database_ready: SUCCESS: Database ${DB_NAME} exists, exiting script at retrycount=$RETRY_COUNT\n${RESET}"
        return 0      # true
      else
        printf "wait_database_ready: Database ${DB_NAME} does not exist. Will sleep ${SLEEP_INTERVAL} seconds and then retry at retry count $RETRY_COUNT\n"
        sleep $SLEEP_INTERVAL
       ((RETRY_COUNT++))
    fi
  done

  printf "\n\n $ERROR*** wait_database_ready: ERROR: Database ${DB_NAME} was not found after ${MAX_RETRIES} retries.$RESET \n\n"
  exit 1
}



##
## Markers in the database
##
#  A marker records that a setup step (e.g. a restore of dante initial system files) has been done on a database. It lives in the database
#  in table DB_MARKER_TABLE with one row per marker. It shares the lifetime of the database volume and not of the wiki container.

DB_MARKER_TABLE=dante_markers

# setting an existing marker again updates its time and description
# returns 0 (true) if the marker has been written, 1 (false) otherwise
# assumes MYSQL_PWD contains the root password
setDBMarker()
{
  local MY_DB_HOST=$1   # name of the database server
  local MY_DB_NAME=$2   # name of the database on this server
  local MARKER=$3       # string describing the mark we made
  local INFO=${4:-}     # string used as optional description 

  printf "*** setDBMarker: setting marker ${MARKER} in database ${MY_DB_NAME}\n"
  if ! mysql -h "${MY_DB_HOST}" -u root --skip-ssl "${MY_DB_NAME}" <<EOF
    CREATE TABLE IF NOT EXISTS ${DB_MARKER_TABLE} (
      name    VARCHAR(255)  NOT NULL PRIMARY KEY,
      set_at  DATETIME      NOT NULL,
      info    VARCHAR(2048) NOT NULL
    );
    INSERT INTO ${DB_MARKER_TABLE} (name, set_at, info) VALUES ($(sqlQuote "${MARKER}"), NOW(), $(sqlQuote "${INFO}"))
      ON DUPLICATE KEY UPDATE set_at = NOW(), info = VALUES(info);
EOF
  then
    printf "${ERROR}*** setDBMarker: could not set marker ${MARKER} in database ${MY_DB_NAME}${RESET}\n"
    return 1      # false
  fi
  return 0        # true
}


# check if marker with a specific string text exists in database on a database server
# returns 0 (true)  if marker exists,
#         1         if marker does not exist or marker table does not exist
#         2         if the check itself failed (server not reachable, wrong password, ...)
#           CAVE: "if checkDBMarker ..." treats 2 like false; callers which must not continue blindly test for 2
# assumes MYSQL_PWD contains the root password
checkDBMarker()
{
  local MY_DB_HOST=$1   # name of DB host
  local MY_DB_NAME=$2   # name of database
  local MARKER=$3       # string text of marker

  local COUNT
  local INFO

  # the marker table may not exist yet; selecting from it would then be an error, not a "false"
  COUNT=$(mysql -h "${MY_DB_HOST}" -u root --skip-ssl -N -s -e \
    "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = $(sqlQuote "${MY_DB_NAME}") AND table_name = $(sqlQuote "${DB_MARKER_TABLE}");") \
    || { printf "${ERROR}*** checkDBMarker: could not check for table ${DB_MARKER_TABLE} in database ${MY_DB_NAME}${RESET}\n"; return 2; }
  if [ "${COUNT}" = "0" ]; then
    printf "*** checkDBMarker: marker ${MARKER} not found in database ${MY_DB_NAME} (no marker table)\n"
    return 1      # false
  fi

  INFO=$(mysql -h "${MY_DB_HOST}" -u root --skip-ssl -N -s "${MY_DB_NAME}" -e \
    "SELECT CONCAT(set_at, ' ', info) FROM ${DB_MARKER_TABLE} WHERE name = $(sqlQuote "${MARKER}");") \
    || { printf "${ERROR}*** checkDBMarker: could not read marker ${MARKER} in database ${MY_DB_NAME}${RESET}\n"; return 2; }
  if [ -n "${INFO}" ]; then
    printf "*** checkDBMarker: marker ${MARKER} found in database ${MY_DB_NAME}: ${INFO}\n"
    return 0      # true
  else
    printf "*** checkDBMarker: marker ${MARKER} not found in database ${MY_DB_NAME}\n"
    return 1      # false
  fi
}


# restore an sql file into a database on a database server, guarded by a marker string
# if the marker table already has a record with this marker string, then the restore is skipped
# after a successful store the marker table has a record with this marker string

# returns 0 (true) if the restore has been done or has been skipped since the marker exists
# exits the calling script with 1 (via failed) if the marker check, the download, the restore or setting the marker fails
# the setting of set -e of the caller is preserved
# assumes MYSQL_PWD contains the root password

#### TODO: aws s3 cp uses (credentials from AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION) but not sure if they are set and if
#### they are needed after all -- issue is: probably yes, for the user based restore since this might be private
#### whereas for the dante system probably not

restoreDatabaseOnce()
{
  local MY_DB_HOST=$1     # name of the database server
  local MY_DB_NAME=$2     # name of the database
  local MARKER=$3         # text of the marker to use for detection.
                          # if marker exists 

  local SOURCE=$4         # method for downloading the sql file: URL for download via curl, S3 for download via aws s3
  local LOCATION=$5       # location for downloading the sql file: a url or an aws identification; if it has a .gz it is unzipped first
  local DESCRIPTION=$6    # description, which also is stored in the marker table, just as comment or for debugging


  local MARKER_STATUS
  local ERREXIT_WAS_ON
  local -a FETCH

  # obtain status of the marker
  if [[ $- == *e* ]]; then ERREXIT_WAS_ON=1; else ERREXIT_WAS_ON=0; fi
  set +e                                                             # set -e switched off for call since a return value of 1 or 2 would abort the script
  checkDBMarker "${MY_DB_HOST}" "${MY_DB_NAME}" "${MARKER}"          # checkDBMarker returns 0 (true), 1 (false) or 2 (check failed)
  MARKER_STATUS=$?                                                   # value of marker
  if [ "${ERREXIT_WAS_ON}" -eq 1 ]; then set -e; fi                  # turn on failing on error again, if the caller had it on

  if [ "${MARKER_STATUS}" -eq 0 ]; then
    printf "*** ${DESCRIPTION} of database ${MY_DB_NAME} already restored, skipping restore\n"
    return 0      # true
  elif [ "${MARKER_STATUS}" -eq 1 ]; then
    printf "*** ${DESCRIPTION} of database ${MY_DB_NAME} not yet restored, will restore now\n"
  else
    failed "checking for marker ${MARKER} in database ${MY_DB_NAME} (returned ${MARKER_STATUS})"
  fi

  # define the command which writes the file to stdout
  case "${SOURCE}" in
    URL)  FETCH=(curl -fsSL "${LOCATION}") ;;
    S3)   FETCH=(aws s3 cp "${LOCATION}" -) ;;
    *)    failed "source of ${DESCRIPTION} must be URL or S3, but is '${SOURCE}'" ;;
  esac

  # pipefail in a subshell: a failing download fails the pipe, without changing the options of the caller
  printf "*** Restoring ${DESCRIPTION} of database ${MY_DB_NAME} from ${SOURCE} ${LOCATION}\n"
  ( set -o pipefail
    "${FETCH[@]}" | { [[ "${LOCATION}" == *.gz ]] && gunzip -c || cat; } | mysql -h ${MY_DB_HOST} -u root --skip-ssl --default-character-set=binary ${MY_DB_NAME}
  ) || failed "restoring ${DESCRIPTION} of database ${MY_DB_NAME} from ${SOURCE} ${LOCATION}"

  setDBMarker "${MY_DB_HOST}" "${MY_DB_NAME}" "${MARKER}" "from ${SOURCE} ${LOCATION}" \
    || failed "setting marker ${MARKER} in database ${MY_DB_NAME}"
  printf "*** DONE restoring ${DESCRIPTION} of database ${MY_DB_NAME}\n"
  return 0        # true
}




listUsers()
{
  local MY_DB_HOST=$1
  printf "${GREEN}*** Listing DB USERS\n${RESET}\n"                
  local OUTPUT=$(mysql -h ${MY_DB_HOST} -u root --skip-ssl  2>&1 <<-EOF
    SELECT User, Host, authentication_string FROM mysql.user;
EOF
  )
if echo "$OUTPUT" | grep -i -q "ERROR"; then
    printf "${ERROR}*** ERROR ${OUTPUT} when listing users${RESET}\n\n"
  else 
    printf "   Command output was \n\n${OUTPUT}\n"
    printf "${GREEN}*** DONE listing USERS${RESET}\n\n"    
  fi
}


listDatabases()
{
  local MY_DB_HOST=$1
  printf "${GREEN}*** Listing DATABASES: ${RESET}\n"
  local OUTPUT=$(mysql -h ${MY_DB_HOST} -u root --skip-ssl 2>&1 <<-EOF
    SHOW DATABASES;
EOF
  )
if echo "$OUTPUT" | grep -i -q "ERROR"; then
    printf "${ERROR}*** ERROR ${OUTPUT} when listing DATABASES ${RESET}\n\n"
  else 
    printf "   Command output was \n\n${OUTPUT}\n"
    printf "${GREEN}*** DONE listing DATABASES ${RESET}\n\n"    
  fi
}

# assumes NEW_MYSQL_PASSWORD contains new password
# assumes MYSQL_PWD contains current, old password
setDBRootpassword()
{
  local MY_DB_HOST="$1"
  printf "${GREEN}***Setting new root password: ${RESET}\n"
  local OUTPUT=$(mysql -h ${MY_DB_HOST}  -u root  --skip-ssl 2>&1 <<-EOF
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_MYSQL_PASSWORD}';
    ALTER USER 'root'@'%' IDENTIFIED BY '${NEW_MYSQL_PASSWORD}';
    flush privileges;
EOF
  )
if echo "$OUTPUT" | grep -i -q "ERROR"; then
    printf "${ERROR}*** ERROR ${OUTPUT} setting new root password ${RESET}\n\n"
  else 
    printf "   Command output was \n\n${OUTPUT}\n"
    printf "${GREEN}*** DONE setting new root password ${RESET}\n\n"    
  fi
}



# fix root permissions by taking away access from every host, restricting it to the container-typical private subnets
# assumes MYSQL_PWD contains root password
# CAvE: Must again grant the necessary rights to user root 
fixRoot()
{
  local MY_DB_HOST="$1"
  printf "${GREEN}*** Fixing root permissions ${RESET}\n"
  local OUTPUT=$(mysql -h ${MY_DB_HOST}  -u root  --skip-ssl  2>&1 <<-EOF
    CREATE USER root@'172.16.0.0/255.240.0.0' IDENTIFIED BY '${MYSQL_PWD}';
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.16.0.0/255.240.0.0' WITH GRANT OPTION;
    CREATE USER root@'192.168.0.0/255.255.0.0' IDENTIFIED BY '${MYSQL_PWD}';
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.0.0/255.255.0.0' WITH GRANT OPTION;
    DELETE FROM mysql.user WHERE user = 'root' AND host = '%';
    FLUSH PRIVILEGES;
    SHOW GRANTS FOR 'root'@'172.16.0.0/255.240.0.0';
    SHOW GRANTS FOR 'root'@'192.168.0.0/255.255.0.0';
EOF
  )
if echo "$OUTPUT" | grep -i -q "ERROR"; then
    printf "${ERROR}*** ERROR ${OUTPUT} when fixing root permissions ${RESET}\n\n"
  else 
    printf "   Command output was \n\n${OUTPUT}\n"
    printf "${GREEN}*** DONE fixing root permissions ${RESET}\n\n"    
  fi
}


# assumes MYSQL_PWD contains the root password
setUserPreference()
{
  local MY_DB_HOST=$1
  local MY_DB_NAME=$2
  local USER_NAME=$3
  local PREFERENCE_NAME=$4
  local PREFERENCE_VALUE=$5


  printf "** Setting preference ${PREFERENCE_NAME} to value ${PREFERENCE_VALUE} in ${MY_DB_NAME} for user ${USER_NAME}\n"
  local OUTPUT=$(mysql -h ${MY_DB_HOST} -u root $MY_DB_NAME  --skip-ssl 2>&1 <<EOF
    INSERT INTO user_properties (up_user, up_property, up_value)
    SELECT user_id, '$PREFERENCE_NAME', '$PREFERENCE_VALUE' 
    FROM user 
    WHERE user_name='$USER_NAME'
    ON DUPLICATE KEY UPDATE up_value='$PREFERENCE_VALUE';
EOF
  )
if echo "$OUTPUT" | grep -i -q "ERROR"; then
    printf "${ERROR}** Error ${OUTPUT} while setting preference ${PREFERENCE_NAME} to value ${PREFERENCE_VALUE} in ${MY_DB_NAME} for user ${USER_NAME}${RESET}\n\n"
  else 
    printf "   Command output was \n\n${OUTPUT}\n"
    printf "${GREEN}** DONE setting preference ${PREFERENCE_NAME} to value ${PREFERENCE_VALUE} in ${MY_DB_NAME} for user ${USER_NAME}${RESET}\n"
  fi
}



# creates database and two users, both identified only in the local networks:
# This separates tasks, unlike MediaWiki's own model where the installer creates a single wiki user with ALL PRIVILEGES.
# Since the installer user cannot GRANT, install.php must not be called with --installdbuser; see init.sh and doc/README-user-concepts.md
createDBandUsers()
{
  local MY_DB_HOST=$1       # name of the database host or container
  local MY_DB_NAME=$2       # name of the entire database we create       
  local MY_DB_USER=$3       # name of runtime user with the permissions to SELECT, INSERT, UPDATE, DELETE, CREATE TEMPORARY TABLES  (used by the running wiki)
  local MY_DB_PASS=$4       # password of runtime user
  local MY_DB_I_USER=$5     # name of installer user with ALL PRIVILEGES, but no GRANT OPTION                       (used by install.php, update.php)
  local MY_DB_I_PASS=$6     # password of installer user

  # refuse to continue with empty values: an empty user would break the SQL batch, an empty password creates a passwordless account
  local VAR
  for VAR in MY_DB_HOST MY_DB_NAME MY_DB_USER MY_DB_PASS MY_DB_I_USER MY_DB_I_PASS; do
    [ -n "${!VAR}" ] || { printf "${ERROR}*** createDBandUsers: ${VAR} is empty or not set in configuration - EXITING${RESET}\n"; exit 1; }
  done

  printf "${GREEN}** Creating database ${MY_DB_NAME} and user ${MY_DB_USER}${RESET}\n"
  local OUTPUT=$(mysql -h ${MY_DB_HOST} -u root --skip-ssl 2>&1 <<-EOF
    CREATE DATABASE IF NOT EXISTS ${MY_DB_NAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;
    CREATE USER IF NOT EXISTS ${MY_DB_USER}@'172.16.0.0/255.240.0.0' IDENTIFIED BY '${MY_DB_PASS}';
    CREATE USER IF NOT EXISTS ${MY_DB_USER}@'192.168.0.0/255.255.0.0' IDENTIFIED BY '${MY_DB_PASS}';
    CREATE USER IF NOT EXISTS ${MY_DB_I_USER}@'172.16.0.0/255.240.0.0' IDENTIFIED BY '${MY_DB_I_PASS}';
    CREATE USER IF NOT EXISTS ${MY_DB_I_USER}@'192.168.0.0/255.255.0.0' IDENTIFIED BY '${MY_DB_I_PASS}';
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE TEMPORARY TABLES ON ${MY_DB_NAME}.* TO '${MY_DB_USER}'@'172.16.0.0/255.240.0.0';
    GRANT SELECT, INSERT, UPDATE, DELETE, CREATE TEMPORARY TABLES ON ${MY_DB_NAME}.* TO '${MY_DB_USER}'@'192.168.0.0/255.255.0.0';
    GRANT ALL PRIVILEGES ON ${MY_DB_NAME}.* TO '${MY_DB_I_USER}'@'172.16.0.0/255.240.0.0';
    GRANT ALL PRIVILEGES ON ${MY_DB_NAME}.* TO '${MY_DB_I_USER}'@'192.168.0.0/255.255.0.0';
    FLUSH PRIVILEGES;
EOF
  )
if echo "$OUTPUT" | grep -i -q "ERROR"; then
    printf "${ERROR}*** ERROR ${OUTPUT} when creating database ${RESET}\n\n"
  else 
    printf "   Command output was \n\n${OUTPUT}\n"
    printf "${GREEN}*** DONE creating database and user ${RESET}\n\n"    
  fi
}



# touch the file LocalSettings.php to refresh the cache
touchLocalSettings()
{
  printf "${GREEN}**** Touching LocalSettings.php to refresh the cache...${RESET}"
    touch ${MOUNT}/${TARGET}/LocalSettings.php
    exec 1>&1 2>&2
  printf "DONE touching LocalSettings.php\n"
}




# Do a update run, needed after extension installation
# Returns the exit status of update.php, so callers can detect a failure
# Runs as the installer user MY_DB_I_USER: schema changes are not possible with the restricted runtime user MY_DB_USER
# that $wgDBuser points to (see doc/README-user-concepts.md)
doMaintenanceUpdate()
{
  printf "\n*** Doing a mediawiki maintenance update ... "
  if ! php ${MOUNT}/${TARGET}/maintenance/update.php --quick --dbuser "${MY_DB_I_USER}" --dbpass "${MY_DB_I_PASS}"; then
    printf "${ERROR}*** ERROR: update.php failed${RESET}\n"
    return 1
  fi
  printf "DONE update.php\n"
}


doPostImportMaintenance()
{
printf "\n\n*** doPostImportMaintenance: RUNNING: initSiteStats \n"
  php ${MOUNT}/${TARGET}/maintenance/initSiteStats.php --update
  exec 1>&1 2>&2
printf "DONE initSiteStats.php\n"

printf "\n\n*** doPostImportMaintenance: RUNNING: rebuildall \n\n"
  php ${MOUNT}/${TARGET}/maintenance/rebuildall.php 
  exec 1>&1 2>&2
printf "DONE rebuildall.php\n"

printf "\n*** doPostImportMaintenance:  RUNNING: checkImages \n"
  php ${MOUNT}/${TARGET}/maintenance/checkImages.php
  exec 1>&1 2>&2
printf "DONE checkImages.php\n"

printf "\n*** doPostImportMaintenance:  RUNNING: refreshFileHeaders \n"
  php ${MOUNT}/${TARGET}/maintenance/refreshFileHeaders.php --verbose
  exec 1>&1 2>&2
printf "DONE refreshFileHeaders.php\n"
}



setApacheAuthentication()
{
  printf "\n*** setApacheAuthentication: removing old password file..."
    rm -f /etc/apache2/.htdigest
  printf "${GREEN}DONE removing old password file\n${RESET}"

  printf "\n*** setApacheAuthentication: Setting password for apache debug user..."
    printf "${APACHE_DEBUG_PASSWORD}\n" | sudo htdigest -c /etc/apache2/.htdigest "Debug Area" "debug"
  printf "DONE setting debug password for apache\n"

  if [ "$USE_APACHE_PASSWORD" = "true" ]; then
    printf "DONE setting debug password for apache\n"
    printf "${APACHE_AUTH_PASSWORD}\n" | sudo htdigest -c /etc/apache2/.htdigest "${APACHE_AUTH_NAME}" "${APACHE_AUTH_USER}"
    printf "DONE setting password for apache for user ${APACHE_AUTH_USER}\n"
  else
    printf "\n*** setApacheAuthentication: not using apache user passwords\n"
  fi
}






# generate an ssh login (private,public) key pair for user USER to login in host HOST
# install the private key at  /root/.ssh/id_rsa of the machine on which this is running
# mail the public key to the user SMTP_TO who then must install this at HOST
# SMTP_FROM is the from address to be used in the envelope
# assumes that the following variables are set in the global environment:
#  SMTP_HOST   SMTP_PORT  SMTP_USER  SMTP_PASSWORD  
generateSshKey()
{
  local USER="$1"
  local HOST="$2"
  local SMTP_TO="$3"
  local SMTP_FROM="$4"

  rm -f /root/.ssh/id_rsa
  rm -f /root/.ssh/id_rsa.pub
  echo "  Existing keys removed"
  ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ''
  echo "  New keys generated"
  # Name of a temporary file for building up the mail
  TMPFILE=`mktemp`
  # generate header in mail file
  ATTACHMENT="/root/.ssh/id_rsa.pub"
  BOUNDARY="ZZ_/afg6432dfgkl.94531q"
    {
      echo "To: $SMTP_TO"         
      echo "From: $SMTP_FROM"       
      echo "Subject: New private key for ssl backup host generated by container " 
      echo "MIME-Version: 1.0"
      echo "Content-Type: multipart/mixed; boundary=\"$BOUNDARY\""
      echo
      echo "--$BOUNDARY"
      echo "Content-Type: text/plain; charset=\"UTF-8\""
      echo "Content-Transfer-Encoding: 7bit"
      echo
      echo "This is the public key generated for the mysql container "
      echo 
      echo "Save the attached file (for example to /tmp/id_rsa.pub) and "
      echo "install it to the ssl backup host using "
      echo 
      echo "ssh-copy-id -i /tmp/id_rsa.pub  ${USER}@${HOST} "
      echo
      echo
      echo "--$BOUNDARY"
      echo "Content-Type: application/octet-stream; name=\"$(basename "$ATTACHMENT")\""
      echo "Content-Transfer-Encoding: base64"
      echo "Content-Disposition: attachment; filename=\"$(basename "$ATTACHMENT")\""
      echo
      base64 "$ATTACHMENT"
      echo
      echo "--$BOUNDARY--"
    } > $TMPFILE
    msmtp --host=${SMTP_HOST} --port=${SMTP_PORT} --auth=on --user=${SMTP_USER} --passwordeval="echo $SMTP_PASSWORD" --tls=on --from=${SMTP_FROM}  ${SMTP_TO} < $TMPFILE
    echo "  New key mailed"

}


