#!/bin/bash

SERVICE_CONTAINER=dante-wiki-container

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

RESET="\e[0m"; ERROR="\e[1;31m"
# 32m for green
# 92m for bold green
GREEN="\e[1;92m"

set -e

### set terminate on error 
abort() 
{
  printf "%b" "\n\n\e[1;31m *** *** *** ABORTED *** *** *** \e[0m"; exit 1 
}

trap 'abort' ERR


printf "\n$GREEN---Taking down configuration...$RESET\n"
  docker-compose -f $TOP_DIR/composer/docker-compose-development.yaml down
printf "$GREEN---DONE$RESET\n" ;

printf "\n$GREEN---Building image dante-wiki if necessary...$RESET\n" ; 
  docker build -t dante-wiki:latest $TOP_DIR/images/dante-wiki/src
printf "$GREEN---DONE$RESET\n"

printf "\n$GREEN---Starting up configuration...$RESET\n" 
# do this in detached mode so as to allow the waiting for the service to start
#  docker-compose -f $TOP_DIR/composer/docker-compose-development.yaml up -d
  docker-compose -f $TOP_DIR/composer/docker-compose-development.yaml up &
printf "$GREEN---DONE$RESET\n"

sleep 10

# Loop to wait for container to run and health check to succeed
SERVER_STATUS="Down"

## first wait until our container is running at all
while [ "$SERVER_STATUS" != "true" ]; do
  printf "\n*** Will check if container is running \n"
  SERVER_STATUS=$(docker inspect --format='{{.State.Running}}' $SERVICE_CONTAINER)
  printf "\n Received on .State.Running: $SERVER_STATUS\n"
  sleep 10
done

# then wait until webserver container status gets healthy 
while [ "$SERVER_STATUS" != "true" ]; do
  printf "\n*** Will check if container is healthy \n"
  SERVER_STATUS=$(docker inspect --format='{{.State.Health.Status}}' $SERVICE_CONTAINER)
  printf "\n Received on .State.Health.Status: $SERVER_STATUS\n"
  if [ "$SERVER_STATUS" == "unhealthy" ]; then
    printf "${ERROR}*** Container considered unhealthy. Good bye. ${RESET}\n"
    exit -1
  fi
  printf "Still waiting for configuration to come up...\n"
  sleep 5
done

printf "${GREEN}*** Webserver is healthy!${RESET}\n"

# wait until webserver is servicing requests
url="https://localhost:4443"
timeout=60
interval=5
start_time=$(date +%s)

while true; do
  if curl --output /dev/null --silent --head --insecure --fail "$url"; then
    printf "${GREEN}*** Webservice is serving requests"
    break
  else
    printf "\nWaiting for the webservice to become ready..."
  fi
  current_time=$(date +%s)
  elapsed_time=$(( current_time - start_time ))
  if [ $elapsed_time -ge $timeout ]; then
    echo "Timed out waiting for the server."
    exit 1
  fi

  sleep 5
done


openChrome