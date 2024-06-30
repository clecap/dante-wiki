#!/bin/bash


SERVICE_CONTAINER=my-lap-container

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

printf "\n$GREEN---Building image if necessary...$RESET\n" ; 
  docker build -t lap:latest -f $TOP_DIR/images/lap/src/Dockerfile  $TOP_DIR/images/lap/src
printf "$GREEN---DONE$RESET\n"

printf "\n$GREEN---Starting up configuration...$RESET\n" 
# do this in detached mode so as to allow the waiting for the service to start
#  docker-compose -f $TOP_DIR/composer/docker-compose-development.yaml up -d
  docker-compose -f $TOP_DIR/composer/docker-compose-development.yaml up &
printf "$GREEN---DONE$RESET\n"


# Loop to wait for health check to succeed
while [  ]; do
  printf "\n*** WIll do check \n"
  docker inspect --format='{{.State.Health.Status}}' $SERVICE_CONTAINER
#  status=$(docker inspect --format='{{.State.Health.Status}}' $SERVICE_CONTAINER)
  printf "Waiting for configuration to come up..\n"
  sleep 5
done

printf "Webserver is healthy is healthy!\n"

if [ `uname` == "Darwin" ]; then 
  printf "\n *** Attempting to start a local Chrome browser\n";
  open -na "Google Chrome" --args --new-window http://localhost:8080/index.html
fi