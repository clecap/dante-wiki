#!/bin/bash

# set -e

DB_NAME="Dante"


MAX_RETRIES=100  ;  SLEEP_INTERVAL=5  ;  RETRY_COUNT=0

RESET="\e[0m"  ;  ERROR="\e[1;31m"  ;  GREEN="\e[1;32m"


MYSQL_PWD=$MY_DB_PASS

# Function to check if the database exists
check_database_exists() {
  RESULT=$(mysql -h $MY_DB_HOST -u root -pdimida -e "SHOW DATABASES LIKE '${DB_NAME}';" 2>&1)
  if [[ "$RESULT" == *"$DB_NAME"* ]]; then
      return 0
    else
      return 1
  fi
}

# Main script logic
printf "\n$GREEN*** This is wait-for-mysql: we are waiting for $MY_DB_HOST to come up\n"
while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
  if check_database_exists; then
      printf "$GREEN*** wait-for-mysql: SUCCESS: Database ${DB_NAME} exists, exiting script at retrycount=$RETRY_COUNT\n" 
      return 0
    else
      printf "Database ${DB_NAME} does not exist. Will sleep ${SLEEP_INTERVAL} seconds and then retry at retry count $RETRY_COUNT\n"
      sleep $SLEEP_INTERVAL
#      printf "*** wait-for-mysql: woke up after sleeping\n"
      ((RETRY_COUNT++))
#      printf "*** just increased retry count to $RETRY_COUNT \n"
  fi
done

printf "\n\n $ERROR*** wait-for-mysql: ERROR: Database ${DB_NAME} was not found after ${MAX_RETRIES} retries.\n\n"
exit 1
