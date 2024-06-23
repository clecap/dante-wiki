#!/bin/bash

# set -e

DB_NAME="Dante"
MAX_RETRIES=100
SLEEP_INTERVAL=5
RETRY_COUNT=0

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
printf "*** wait-for-mysql: entering loop $MY_DB_HOST\n"
while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
  printf "*** wait-for-mysql: will do a check now\n"
  if check_database_exists; then
      printf "*** wait-for-mysql: Database ${DB_NAME} exists, exiting script\n" 
      return 0
    else
      printf "Database ${DB_NAME} does not exist. Will sleep ${SLEEP_INTERVAL} seconds and then retry...\n"
      sleep $SLEEP_INTERVAL
      printf "*** wait-for-mysql: woke up after sleeping\n"
      ((RETRY_COUNT++))
      printf "*** just increased retry count to $RETRY_COUNT \n"
  fi
done

printf "Database ${DB_NAME} was not found after ${MAX_RETRIES} retries.\n\n"
exit 1

