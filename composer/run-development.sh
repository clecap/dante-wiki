#!/bin/bash

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
  docker-compose -d -f $TOP_DIR/composer/docker-compose-development.yaml up 
printf "$GREEN---DONE$RESET\n"



# Function to check the health status of a service
check_health() {
  service=$1
  status=$(docker inspect --format='{{.State.Health.Status}}' )
  echo $status
}

# List of services to check
services=("web")

# Loop until all services are healthy
for service in "${services[@]}"; do
  while [ "$(check_health $service)" != "healthy" ]; do
    echo "Waiting for $service to be healthy..."
    sleep 5
  done
  echo "$service is healthy!"
done

if [ `uname` == "Darwin" ]; then 
  echo ""; echo "*** Attempting to start a local Chrome browser - this may fail"; echo "";
  open -a "Google Chrome"  http://localhost:8080/index.html
fi