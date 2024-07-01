#!/bin/bash


SERVICE_CONTAINER=my-lap-container

# get directory where this script resides wherever it is called from
export DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export TOP_DIR=${DIR}/.. 


export RESET="\e[0m"; export ERROR="\e[1;31m"; export GREEN="\e[1;92m"



printf "\n$GREEN---Taking down configuration...$RESET\n"
  docker-compose -f $TOP_DIR/composer/docker-compose-development.yaml down
printf "$GREEN---DONE$RESET\n" ;

printf "\n$GREEN---Building image if necessary...$RESET\n" ; 
  docker build -t lap:latest -f $TOP_DIR/images/lap/src/Dockerfile  $TOP_DIR/images/lap/src
printf "$GREEN---DONE$RESET\n"

printf "\n$GREEN---Starting up configuration...$RESET\n" 
# do this in detached mode so as to allow the waiting for the service to start
#  docker-compose -f $TOP_DIR/composer/docker-compose-development.yaml up -d
  docker-compose -f $TOP_DIR/composer/docker-compose-development.yaml up &
printf "$GREEN---DONE$RESET\n"

sleep 10



waitForRun 
{
# Loop to wait for container to run and health check to succeed
SERVER_STATUS="Down"

## first wait until our container is running at all
while [ "$SERVER_STATUS" != "true" ]; do
  printf "\n*** Will check if container is running \n"
  SERVER_STATUS=$(docker inspect --format='{{.State.Running}}' $SERVICE_CONTAINER)
  printf "\n Received on .State.Running: $SERVER_STATUS\n"
  sleep 10
done


}

waitForHealthy 
{
# then wait until it gets healthy 
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

if [ `uname` == "Darwin" ]; then 
  printf "\n *** Attempting to start a local Chrome browser\n";
  open -na "Google Chrome" --args --new-window http://localhost:8080/index.html
fi
}