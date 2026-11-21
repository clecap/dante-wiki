#!/bin/bash

##
## Check the status of the database container while executing this on one of the dante wiki containers
##

source /home/dante/dantescript/common-defs.sh

loadSecrets

wait_dbserver_running "${MY_DB_HOST}"   # wait for the database container to come up properly



if check_dbserver_initial_rootpassword "${MY_DB_HOST}"; then     # branch taken when db server still running initial root password
  printf "${GREEN}\n\n*** prepare-database.sh: We are running on the initial database root password...now setting up database system\n"

  export MYSQL_PWD="initialPassword"
  listUsers             "${MY_DB_HOST}"
  listDatabases         "${MY_DB_HOST}"

  export NEW_MYSQL_PASSWORD="${MYSQL_ROOT_PASSWORD}"  # overwrite with initial password
  setDBRootpassword     "${MY_DB_HOST}"
  export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"   # from now on we have to use the newly set password

  listUsers             "${MY_DB_HOST}"
  fixRoot               "${MY_DB_HOST}"       # give root reduced permissions
  listUsers             "${MY_DB_HOST}"

  printf "${GREEN}\n\n*** prepare-database.sh: We have initialized the database system \n"
fi

export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"   # we have to use the password of the configuration

if check_dbserver_has_database "${MY_DB_HOST}" "${MY_DB_NAME}"; then     # branch taken db server has database of given name
  printf "${GREEN}*** prepare-database.sh: Database host ${MY_DB_HOST} has a database named ${MY_DB_NAME}\n"
else
  printf "${GREEN}*** prepare-database.sh: Database host ${MY_DB_HOST} has NO a database named ${MY_DB_NAME}\n"

  listUsers             "${MY_DB_HOST}"
  listDatabases         "${MY_DB_HOST}"
  createDBandUsers      "${MY_DB_HOST}" "${MY_DB_NAME}" "${MY_DB_USER}" "${MY_DB_PASS}" "${MY_DB_I_USER}" "${MY_DB_I_PASS}"
  listUsers             "${MY_DB_HOST}"
  listDatabases         "${MY_DB_HOST}"
fi

#
# TODO: now chec marker and do restore if necessary - maybe in separate shell script since we not always want to do it
#