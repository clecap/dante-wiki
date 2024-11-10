#!/bin/bash

##
## Prepare the database container while executing on the dantewiki container
##
#
#  This approach has the advantage that we do not need further scripts for the database container
#  and can just use the standard configuration
#

source /home/dante/dantescript/common-defs.sh

loadSecrets

banner "PREPARE-DATABASE"

wait_dbserver_running ${MY_DB_HOST}

check_dbserver_initial_rootpassword ${MY_DB_HOST}
RESULT=$?

if [ $RESULT -eq 1 ]; then
  printf "${GREEN}\n\n*** prepare-database.sh: We are running on initial root password...setting up database\n"
  export MYSQL_PWD="initialPassword"

  listUsers             "${MY_DB_HOST}"
  listDatabases         "${MY_DB_HOST}"
  createDBandUsers      "${MY_DB_HOST}" "${MY_DB_NAME}" "${MY_DB_USER}" "${MY_DB_PASS}"
  listUsers             "${MY_DB_HOST}"
  listDatabases         "${MY_DB_HOST}"

  export NEW_MYSQL_PASSWORD="${MYSQL_ROOT_PASSWORD}"  # overwrite with initial password

  exec 1>&1 2>&2

  setDBRootpassword     "${MY_DB_HOST}"

# from now on we have to use the newly set password
export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"

  listUsers             "${MY_DB_HOST}"
  fixRoot                "${MY_DB_HOST}"
  listUsers             "${MY_DB_HOST}"

else
  printf "${GREEN}\n\n*** prepare-database.sh: We are running on the set root password...waiting for database\n"
  wait_database "Dante"
fi

