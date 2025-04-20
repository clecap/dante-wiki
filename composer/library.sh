#!/bin/bash

#
# Library functions for composing Docker constellation for DanteWiki
#

# bash color codes
export RESET="\e[0m"; 
export ERROR="\e[1;31m"; 
export GREEN="\e[1;92m"



abort() 
{
  printf "%b" "\n\n$ERROR *** *** *** ABORTED *** *** *** $RESET"; exit 1 
}


# Declare a global variable to store the start time
TIMER_START=0

startTimer() {
  TIMER_START=$(date +%s)
}


ok() {
  local end_time=$(date +%s)
  local elapsed_time=$((end_time - TIMER_START))
  printf $1
  printf "Time spent: ${elapsed_time} seconds"
}

error() {
  local end_time=$(date +%s%N)
  local elapsed_time=$((end_time - TIMER_START))
  printf $1
  print "Time spent: ${elapsed_time} seconds"
}


demoTime()
{
  startTimer
  sleep 3  # Simulate some processing time
  stopTimer
}


# wait until webserver is servicing requests
waitForWebserverServicing()
{
  local url="https://localhost:4443"
  local timeout=240
  local interval=10
  
  local start_time=$(date +%s)

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

    sleep $interval
  done
}


# wait until container $1 is running
waitForContainerRunning()
{
  local SERVICE_CONTAINER=$1
  local interval=10

  local SERVER_STATUS="Down"
  while [ "$SERVER_STATUS" != "true" ]; do
    printf "\n*** Will check if container ${SERVICE_CONTAINER} is running \n"
    SERVER_STATUS=$(docker inspect --format='{{.State.Running}}' $SERVICE_CONTAINER)
    printf "\n Received on .State.Running: $SERVER_STATUS\n"
    sleep $interval
  done
}


# wait until container $1 is healthy
#
# NOTE: not used since for some reason the conatiner shows unhealthy for a while before becoming healthy again
waitForContainerHealthy()
{
  local SERVICE_CONTAINER=$1

  local interval=5
  local SERVER_STATUS="Down"
  while [ "$SERVER_STATUS" != "healthy" ]; do
    printf "\n*** Will check if container $SERVICE_CONTAINER is healthy \n"
    SERVER_STATUS=$(docker inspect --format='{{.State.Health.Status}}' $SERVICE_CONTAINER)
    printf "\n Received on .State.Health.Status: $SERVER_STATUS\n"
    if [ "$SERVER_STATUS" == "unhealthy" ]; then
      printf "${ERROR}*** Container $SERVICE_CONTAINER considered unhealthy. Good bye. ${RESET}\n"
      exit -1
    fi
    printf "Still waiting for container $SERVICE_CONTAINER to come up...\n"
    sleep $interval
  done
  printf "${GREEN}*** Webserver is healthy!${RESET}\n"
}


# if running darwin, open chrome
openChrome()
{
  if [ `uname` == "Darwin" ]; then 
    printf "\n*** openChrome: Attempting to start a local Chrome browser\n";
    open -na "Google Chrome" --args --new-window https://localhost:4443/wiki-dir/
  fi
}


# take down all services of composer file $1
downAllServices()
{
  printf "\n$GREEN---Taking down configuration...$RESET\n"
  docker compose -f $1 down
  printf "$GREEN---DONE$RESET\n" ;
}

# fire up in composer file $1 the services $2 $3 ...
upServices()
{
  local compose_file=$1
  shift
  docker compose -f "$compose_file" up -d "$@"
}


build() 
{
  startTimer
  printf "\n$GREEN---Building image dante-wiki if necessary...$RESET\n" ; 
    docker build -t dante-wiki:latest $TOP_DIR/images/dante-wiki/src
  ok "$GREEN---DONE$RESET\n"
}



cook()
{
 local container_name=$1
  # Use docker ps -aqf to get the container ID based on the name
  local container_id=$(docker ps -aqf "name=^${container_name}$")

  if [ -n "$container_id" ]; then
    printf "Container ID: $container_id"
  else
    printf "${ERROR}*** No container found with name: ${container_name} \n"
  exit -1
  fi

  docker commit $container_id dante-wiki:cooked

  printf "Tagging to cooked\n"
    docker tag dante-wiki:cooked clecap/dante-wiki:cooked
  printf "DONE tagging to cooked"


}




# cookImage dante-wiki-container 
cooked_to_DockerHub()
{
  # TODO
  # Docker Hub credentials
  DOCKER_USERNAME="your_dockerhub_username"
  DOCKER_TOKEN="your_dockerhub_token"

  # Login to Docker Hub using the token
  echo "$DOCKER_TOKEN" | docker login --username "$DOCKER_USERNAME" --password-stdin

####docker login ##### TODO
#  docker push clecap/dante-wiki:cooked 
  docker logout

}

# needs a classic token with   write:packages, read:packages, and delete:packages scopes

# NOT WORKING: contents: read and write   meta-data read only    package: read and write

cooked_to_GitHub()
{

  local USERNAME=clecap
  local GITHUB_TOKEN=$TOKEN_FOR_GITHUB_REGISTRY

  echo $GITHUB_TOKEN | docker login ghcr.io -u $USERNAME --password-stdin

  # put this to dante-wiki or to dante-wiki-contents ??  or production????
  printf "Tagging cooked to github cooked\n"
    docker tag dante-wiki:cooked ghcr.io/clecap/dante-wiki:cooked
  printf "DONE tagging to github cooked\n"

  printf "Pushing to github registry\n"
    docker push ghcr.io/clecap/dante-wiki:cooked
  printf "DONE pushing to github\n"

  docker logout
}


# obtains information of the image $1 and exports it into the shell
getImageInfo()
{
  local IMAGE="$1"
  export IMAGE_ID=$(docker images ${IMAGE} --format "{{.ID}}")
  export IMAGE_DIGEST=$(docker images ${IMAGE} --format "{{.Digest}}")
  export IMAGE_REPOSITORY=$(docker images ${IMAGE} --format "{{.Repository}}")
  export IMAGE_CREATED_AT=$(docker images ${IMAGE} --format "{{.CreatedAt}}")
  export IMAGE_TAG==$(docker images ${IMAGE} --format "{{.Tag}}")
}








