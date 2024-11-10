#!/bin/bash

# Common environment variables and definitions for all dantescript scripts

##
## Configurables
##
export PARSIFAL_BRANCH="dante"

# the name of the branch to which we will clone
DANTE_BRANCH=master

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
export GREEN="\e[1;92m"



git config --global init.defaultBranch master



# Pre-execution trap to capture the line number before each command is run
trap 'export LAST_COMMAND_LINE=$LINENO' DEBUG


# trap handler which sleeps after taking the trap for 1 hour for
abort() 
{ 
  banner
  printf "Error in line number $LAST_COMMAND_LINE of ${BASH_SOURCE[0]} at command $BASH_COMMAND \n";
  banner
  printf "\n\n*** abort: Sleeping for 1 hour to keep container running for debug attempts ***\n\n ${RESET}"
  sleep 3600
}

# trap handler which prints a highly visible warning and then continues
warn()
{
  banner
  printf "The error occured in line number $LINENO: of $BASH_COMMAND \n";
  banner
}


banner()
{
 if [ $# -eq 0 ]; then
    printf "\n\n${ERROR} *** *** *** ****** *** *** *** ${RESET}\n"; 
    printf     "${ERROR} *** *** *** ****** *** *** *** ${RESET}\n"; 
  else
    local input="$1"
    printf "\n\n${ERROR} *** *** *** ****** *** *** *** ${RESET}\n"; 
    printf     "${ERROR} *** *** *** ****** *** *** *** ${RESET}\n"; 
    printf     "${ERROR} ***  ${input^^}  ${RESET}\n";
    printf     "${ERROR} *** *** *** ****** *** *** *** ${RESET}\n"; 
    printf     "${ERROR} *** *** *** ****** *** *** *** ${RESET}\n\n"; 
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


## Load the secret configuration file
loadSecrets()
{
  if [ -f "/run/secrets/configuration" ]; then
    printf "$GREEN*** common-defs.sh:loadSecrets will now load configuration...${RESET} "
    source /run/secrets/configuration ; exec 1>&1 2>&2
    export DANTE_CONFIG_HASH=$(shasum -a 256 /run/secrets/configuration | awk '{ print $1 }')
    printf "DONE\n   loading configuration, hashed to ${DANTE_CONFIG_HASH}\n"
  else
    printf "$ERROR*** common-defs.sh:loadSecrets could not find configuration file, EXITING $RESET\n"
    exit 1
  fi
}

# Change database root password to a new root password
# Call as changeDBRootPassword "old-password" "new-password"
changeDBRootPassword()
{
  local db_host="mariadb_container_hostname_or_ip"
  local db_port="3306"  # Default MariaDB/MySQL port
  local current_root_password=$1
  local new_root_password=$2

  printf "Executing the SQL command to change the database root password for %  \n"
    mysql -h "${db_host}" -P "${db_port}" -u root -p"${current_root_password}" -e "ALTER USER 'root'@'%' IDENTIFIED BY '${new_root_password}'; FLUSH PRIVILEGES;"
  if [ $? -eq 0 ]; then
    printf "${GREEN}Root password of database has been successfully changed for @.${RESET}"
  else
    printf "${ERROR}Failed to change the database root password for @.${RESET}"
  fi

  printf "Executing the SQL command to change the database root password for localhost \n"
    mysql -h "${db_host}" -P "${db_port}" -u root -p"${current_root_password}" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${new_root_password}'; FLUSH PRIVILEGES;"
  if [ $? -eq 0 ]; then
    printf "${GREEN}Root password of database has been successfully changed for localhost.${RESET}"
  else
    printf "${ERROR}Failed to change the database root password for localhost.${RESET}"
  fi
}




changeWikiRootUser()
{
  local current_username="Admin"             # Current admin username
  local new_username="NewAdminName"          # New admin username
  local new_password="new_password"          # New password for the admin account

  printf "Renaming the administrator username from $current_username to $new_username\n"
  php "${MOUNT}${TARGET}/maintenance/renameUser.php" --olduser="${current_username}" --newuser="${new_username}" --reason="Automated username change"
  if [ $? -eq 0 ]; then
    printf "${GREEN}Administrator username has been successfully changed to ${new_username}. ${RESET}\n"
  else
    printf "${ERROR}Failed to change the Wiki administrator username.\n ${RESET}"
    exit 1
  fi

  printf "Changing the password for the new administrator username \n"
  php "${MOUNT}${TARGET}/maintenance/changePassword.php" --user="${new_username}" --password="${new_password}"

  if [ $? -eq 0 ]; then
    printf "${GREEN}Administrator password has been successfully changed.\n${RESET}"
  else
   printf "${ERROR}Failed to change the administrator password. \n${RESET}"
  fi
}









# Function to check if the database server is running; returns true if it is running
#### TODO
#### CAVE: NEEDS correct password !!!
ping_dbserver() {
  local MY_DB_HOST="$1"
  printf "check_dbserver_running: Pinging database $MY_DB_HOST \n"
  mysqladmin ping -h "$MY_DB_HOST"


  sleep 600000

  RESULT=$?
  printf "mysqladmin returned $RESULT"
  if [ $RESULT -eq 0 ]; then
    printf "ping_dbserver: Returning true-ish\n"
    return 1  # True-ish
  else
    printf "ping_dbserver: Returning false-ish\n"
    return 0  # False-ish
  fi
}



check_dbserver_running() {
  local MYSQL_HOST="$1"
  local MYSQL_PORT=3306

# Use /dev/tcp to check if the MySQL server is reachable
  if (echo > /dev/tcp/$MYSQL_HOST/$MYSQL_PORT) &> /dev/null; then
    printf "   check_dbserver_running: MySQL server ${MYSQL_HOST} is up\n"
    return 1
  else
    printf "   check_dbserver_running: MySQL server ${MYSQL_HOST} is down or unreachable\n"
    return 0
  fi
}





wait_dbserver_running() {
  local MY_DB_HOST="$1"
  local MAX_RETRIES=100    
  local SLEEP_INTERVAL=5  
  local RETRY_COUNT=0
  local RESULT

  printf "\n$GREEN*** This is wait_dbserver_running: we are waiting for $MY_DB_HOST to come up${RESET}\n"
  while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    check_dbserver_running "$MY_DB_HOST"
    RESULT=$?
    if [ "$RESULT" == "1" ]; then
      printf "$GREEN*** wait_dbserver_running: SUCCESS: Database server is running, exiting script at retrycount=$RETRY_COUNT\n ${RESET}" 
      return 1
    elif [ "$RESULT" == "0" ]; then
      printf "   wait_dbserver_running: Database server does not exist. Will sleep ${SLEEP_INTERVAL} seconds and then retry. We are at retry count $RETRY_COUNT\n"
      sleep $SLEEP_INTERVAL
      ((RETRY_COUNT++))
    else
      printf "wait_dbserver_running: The variable does not contain 1 or 0"
    fi
  done
  printf "\n\n $ERROR*** wait_dbserver_running: ERROR: Database server not running after ${MAX_RETRIES} retries.\n\n${RESET}"
  sleep 600000
  exit 1
}



check_dbserver_initial_rootpassword() {
  local MY_DB_HOST="$1"
  if mysqladmin ping -u root -pinitialPassword -h "$MY_DB_HOST"; then
    printf "check_dbserver_initial_password: db server is running and initial password is ok.\n"
    return 1
  else
    printf "check_dnserver_initial_password: db server is not running or initial password is incorrect.\n"
    return 0
  fi
}



# Function to check if the database $1 exists and is running
check_database_exists() {
  local DB_NAME="$1"
  local RESULT=$(mysql -h $MY_DB_HOST -u root -p${MY_DB_PASS} -e "SHOW DATABASES LIKE '${DB_NAME}';" 2>&1)
  if [[ "$RESULT" == *"$DB_NAME"* ]]; then
      printf "check_database_exists did not find database ${DB_NAME}"
      return 0
    else
      printf "check_database_exists found database ${DB_NAME}"
      return 1
  fi
}



wait_database_ready() {
  local DB_NAME="$1"
  local MAX_RETRIES=100
  local SLEEP_INTERVAL=5
  local RETRY_COUNT=0
  printf "\n$GREEN*** wait_database_ready: Waiting for $MY_DB_HOST to come up with ${DB_NAME}\n${RESET}"
  while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
    if check_database_exists; then
        printf "$GREEN*** wait_database_ready: SUCCESS: Database ${DB_NAME} exists, exiting script at retrycount=$RETRY_COUNT\n${RESET}" 
        return 0
      else
        printf "wait_database_ready: Database ${DB_NAME} does not exist. Will sleep ${SLEEP_INTERVAL} seconds and then retry at retry count $RETRY_COUNT\n"
        sleep $SLEEP_INTERVAL
       ((RETRY_COUNT++))
    fi
  done

  printf "\n\n $ERROR*** wait_database_ready: ERROR: Database ${DB_NAME} was not found after ${MAX_RETRIES} retries.$RESET \n\n"
  exit 1
}








listUsers()
{
  local MY_DB_HOST=$1
  printf "${GREEN}*** Listing DB USERS\n${RESET}"                
  mysql -h ${MY_DB_HOST} -u root   <<-EOF
    SELECT User, Host, authentication_string FROM mysql.user;
EOF
  if [ $? -ne 0 ]; then
    printf "${ERROR}*** ERROR when listing users${RESET}\n\n"
  else 
    printf "${GREEN}*** DONE listing USERS${RESET}\n\n"    
  fi
}


listDatabases()
{
  local MY_DB_HOST=$1
  printf "${GREEN}*** Listing DATABASES: \n"
  mysql -h ${MY_DB_HOST} -u root <<-EOF
    SHOW DATABASES;
EOF
  printf "${GREEN}*** DONE listing databases${RESET}\n\n"
}

# assumes NEW_MYSQL_PASSWORD contains new password
# assumes MYSQL_PWD contains current, old password
setDBRootpassword()
{
  local MY_DB_HOST="$1"
  printf "** Setting new root password: \n"
  mysql -h ${MY_DB_HOST}  -u root <<-EOF
    ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_MYSQL_PASSWORD}';
    ALTER USER 'root'@'%' IDENTIFIED BY '${NEW_MYSQL_PASSWORD}';
    flush privileges;
EOF
  printf "DONE setDBRootpassword\n"
}



# fix root permissions by taking away access from every host, restricting it to the container-typical private subnets
# assumes MYSQL_PWD contains root password
# CAvE: Must again grant the necessary rights to user root 
fixRoot()
{
  local MY_DB_HOST="$1"
  printf "${GREEN}** Fixing root permissions ${RESET}\n"
  mysql -h ${MY_DB_HOST}  -u root <<-EOF
    CREATE USER root@'172.16.0.0/255.240.0.0' IDENTIFIED BY '${MYSQL_PWD}';
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'172.16.0.0/255.240.0.0' WITH GRANT OPTION;
    CREATE USER root@'192.168.0.0/255.255.0.0' IDENTIFIED BY '${MYSQL_PWD}';
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.168.0.0/255.255.0.0' WITH GRANT OPTION;
    DELETE FROM mysql.user WHERE user = 'root' AND host = '%';
    FLUSH PRIVILEGES;
    SHOW GRANTS FOR 'root'@'172.16.0.0/255.240.0.0';
    SHOW GRANTS FOR 'root'@'192.168.0.0/255.255.0.0';
EOF
  if [ $? -ne 0 ]; then
    printf "${ERROR}*** ERROR when fixing root permissions ${RESET}\n\n"
  else 
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


  printf "${GREEN}** Setting preference ${PREFERENCE_NAME} to value ${PREFERENCE_VALUE} in ${MY_DB_NAME} for user ${USER_NAME}${RESET}\n"
  ERROR_OUTPUT=$(mysql -h ${MY_DB_HOST} -u root $MY_DB_NAME <<EOF
    INSERT INTO user_properties (up_user, up_property, up_value)
    SELECT user_id, '$PREFERENCE_NAME', '$PREFERENCE_VALUE' 
    FROM user 
    WHERE user_name='$USER_NAME'
    ON DUPLICATE KEY UPDATE up_value='$PREFERENCE_VALUE';
EOF
  )
  if [ $? -ne 0 ]; then
    printf "${ERROR}** Error ${ERROR_OUTPUT} while setting preference ${PREFERENCE_NAME} to value ${PREFERENCE_VALUE} in ${MY_DB_NAME} for user ${USER_NAME}${RESET}\n\n"
  else 
    printf "${GREEN}** DONE setting preference ${PREFERENCE_NAME} to value ${PREFERENCE_VALUE} in ${MY_DB_NAME} for user ${USER_NAME}${RESET}\n"
  fi
}


# export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"

# creates database $2 and user $3  identified in local network by password $4 with full privileges on that database
createDBandUsers()
{
  local MY_DB_HOST=$1
  local MY_DB_NAME=$2
  local MY_DB_USER=$3
  local MY_DB_PASS=$4
  printf "${GREEN}** Creating database ${MY_DB_NAME} and user ${MY_DB_USER}${RESET}\n"
  ERROR_OUTPUT=$(mysql -h ${MY_DB_HOST} -u root 2>&1 <<-EOF
    CREATE DATABASE IF NOT EXISTS ${MY_DB_NAME} /*\!40100 DEFAULT CHARACTER SET utf8 */;
    CREATE USER IF NOT EXISTS ${MY_DB_USER}@'172.16.0.0/255.240.0.0' IDENTIFIED BY '${MY_DB_PASS}';
    CREATE USER IF NOT EXISTS ${MY_DB_USER}@'192.168.0.0/255.255.0.0' IDENTIFIED BY '${MY_DB_PASS}';
    GRANT ALL PRIVILEGES ON ${MY_DB_NAME}.* TO '${MY_DB_USER}'@'172.16.0.0/255.240.0.0';
    GRANT ALL PRIVILEGES ON ${MY_DB_NAME}.* TO '${MY_DB_USER}'@'192.168.0.0/255.255.0.0';
    FLUSH PRIVILEGES;
EOF
  )
  if [ $? -ne 0 ]; then
    printf "${ERROR}*** ERROR when creating database and user was $ERROR_OUTPUT ${RESET}\n\n"
  else 
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
doMaintenanceUpdate()
{
  printf "\n*** Doing a mediawiki maintenance update ... "
    php ${MOUNT}/${TARGET}/maintenance/update.php
    exec 1>&1 2>&2
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












