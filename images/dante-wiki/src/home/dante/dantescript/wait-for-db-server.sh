#!/bin/bash

DB_NAME="Dante"

MAX_RETRIES=100  ;  SLEEP_INTERVAL=5  ;  RETRY_COUNT=0

source /home/dante/dantescript/common-defs.sh

MYSQL_PWD=$MY_DB_PASS


# Function to check if the database exists
check_database_running() {
  printf "Pinging database\n"
  mysqladmin ping -h "$MY_DB_HOST" -u root -pinitialPassword --silent
  if [ $? -eq 0 ]; then
    printf "Returning true-ish\n"
    return 0  # True-ish
  else
    printf "Returning false-ish\n"
    return 1  # False-ish
  fi
}



# Main script logic
printf "\n$GREEN*** This is wait-for-db: we are waiting for $MY_DB_HOST to come up\n"
while [[ $RETRY_COUNT -lt $MAX_RETRIES ]]; do
  if check_database_running; then
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
