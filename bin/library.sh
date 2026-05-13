#!/bin/bash

#
# Library functions for composing Docker constellation for DanteWiki
#

# bash color codes
export RESET="\e[0m"; 
export ERROR="\e[1;31m"; 
export GREEN="\e[1;92m";





printBanner()
{
  printf "\n"
  printf "****************************\n"
  printf "*** QUICK INSTALLER ${VERSION} ***\n"
  printf "****************************\n\n" 
  printf "\n"
  printf "* Running from current working directory ${PWD} \n"
  printf "* Will be installing into ${INSTALL_DIR} \n"
  printf "\n"
  read -p "Proceed ? [y/N] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
}



abort()
{
  printf "%b" "\n\n$ERROR *** *** *** ABORTED *** *** *** $RESET"; exit 1
}


askConfirmation()
{
  local message="${1:-Are you sure ??}"
  printf "%b" "\n${ERROR}${message}${RESET} [y/N] "
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]] || abort
}


# Declare a global variable to store the start time
TIMER_START=0

startTimer() {
  TIMER_START=$(date +%s)
}


start() {
  printf "${GREEN}$1${RESET}\n"
  TIMER_START=$(date +%s)
}


ok() {
  local end_time=$(date +%s)
  local elapsed_time=$((end_time - TIMER_START))
  printf "${GREEN}$1  ${RESET}  Time spent: ${elapsed_time} [sec] \n\n"
}

error() {
  local end_time=$(date +%s%N)
  local elapsed_time=$((end_time - TIMER_START))
  printf "${ERROR}$1  ${RESET} Time spent: ${elapsed_time} [sec]"
}


demoTime()
{
  startTimer
  sleep 3  # Simulate some processing time
  stopTimer
}



doInstallWithGIT()
{
  printf "*** install.sh: Will clone branch $GIT_BRANCH from https://github.com/$GIT_OWNER/$GIT_REPO.git to ${INSTALL_DIR}\n\n"
  read -p "Proceed with cloning? [y/N] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
  git clone --depth 1 --branch $GIT_BRANCH https://github.com/$GIT_OWNER/$GIT_REPO.git ${INSTALL_DIR}
}






# wait until webserver is servicing requests
waitForWebserverServicing()
{
  local url=${MW_SITE_SERVER}
  local timeout=240
  local interval=10
  
  local start_time=$(date +%s)

  while true; do
    if curl --output /dev/null --silent --head --insecure --fail "$url"; then
      printf "${GREEN}*** Webservice is serving requests at $url $RESET \n"
      break
    else
      printf "Waiting for the webservice to become ready at $url \n"
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


# if running darwin, open a fresh local chrome browser instance on the newly generated service
openChrome()
{
  if [ `uname` == "Darwin" ]; then 
    printf "\n*** openChrome: Attempting to start a local Chrome browser\n";
    open -na "Google Chrome" --args --new-window ${MW_SITE_SERVER}
  fi
}


# take down all services of composer file $1
downAllServices()
{
  printf "Currently running docker processes are:\n"
  docker ps
  printf "\n\n"
  askConfirmation "Did you *** SAVE *** the  (1) GIT files and (2) the SYSTEM files and (3) the USER content - we will now down all services an status will no longer be recoverable !!"
  printf "\n$GREEN---Taking down configuration...$RESET\n"
  docker compose -f $1 down
  printf "$GREEN---DONE$RESET\n" ;
}

# fire up in composer file $1 the services $2 $3 ...
upServices()
{
  local compose_file=$1
  shift
  printf "DOING: docker compose -f \"$compose_file\" up -d \"$@\"  \n\n"
  docker compose -f "$compose_file" up -d "$@"
}



# build the docker image
build() 
{
  startTimer
  printf "\n$GREEN---Building image dante-wiki if necessary...$RESET\n" ; 
    docker build -t dante-wiki:latest $TOP_DIR/images/dante-wiki/src
  ok "$GREEN---DONE$RESET"
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


# obtains information of the image $1, prints it and exports it into the shell
getImageInfo()
{
  local IMAGE="$1"
  export IMAGE_ID=$(docker image inspect "${IMAGE}" --format "{{.ID}}")
  export IMAGE_CREATED_AT=$(docker image inspect "${IMAGE}" --format "{{.Created}}")
  export IMAGE_SIZE=$(docker image inspect "${IMAGE}" --format "{{.Size}}")
  export IMAGE_REPO_TAG=$(docker image inspect "${IMAGE}" --format "{{index .RepoTags 0}}")
  export IMAGE_REPOSITORY=$(echo "${IMAGE_REPO_TAG}" | cut -d: -f1)
  export IMAGE_TAG=$(echo "${IMAGE_REPO_TAG}" | cut -d: -f2)
  export IMAGE_DIGEST=$(docker image inspect "${IMAGE}" --format "{{index .RepoDigests 0}}")
  export IMAGE_ARCH=$(docker image inspect "${IMAGE}" --format "{{.Architecture}}")
  export IMAGE_OS=$(docker image inspect "${IMAGE}" --format "{{.Os}}")
  export IMAGE_LAYERS=$(docker image inspect "${IMAGE}" --format "{{len .RootFS.Layers}}")
  export IMAGE_LABELS=$(docker image inspect "${IMAGE}" --format "{{json .Config.Labels}}")
  export IMAGE_LAST_TAGGED=$(docker image inspect "${IMAGE}" --format "{{.Metadata.LastTagTime}}")

  printf "\n"
  printf "IMAGE            = $IMAGE\n"
  printf "IMAGE_ID         = $IMAGE_ID\n"
  printf "IMAGE_REPO_TAG   = $IMAGE_REPO_TAG\n"
  printf "IMAGE_REPOSITORY = $IMAGE_REPOSITORY\n"
  printf "IMAGE_TAG        = $IMAGE_TAG\n"
  printf "IMAGE_DIGEST     = $IMAGE_DIGEST\n"
  printf "IMAGE_CREATED_AT = $IMAGE_CREATED_AT\n"
  printf "IMAGE_SIZE       = $IMAGE_SIZE\n"
  printf "IMAGE_ARCH       = $IMAGE_ARCH\n"
  printf "IMAGE_OS         = $IMAGE_OS\n"
  printf "IMAGE_LAYERS     = $IMAGE_LAYERS\n"
  printf "IMAGE_LABELS:\n"
  docker image inspect "${IMAGE}" --format '{{range $k, $v := .Config.Labels}}  {{$k}} = {{$v}}
{{end}}'
  printf "IMAGE_LAST_TAGGED= $IMAGE_LAST_TAGGED\n"
  printf "\n\n"
}



# check if still needed, probably deprecated
checkOldInstallation() 
{
  if [ -d ${INSTALL_DIR} ]; then
    echo "*** quick-install.sh: Found an old installation directory at ${INSTALL_DIR} "
    echo "    k     Keep configuration and keys, delete remaining installation at ${INSTALL_DIR} [DEFAULT: press return]"
    echo "    d     Delete configuration, delete installation, keep keys "
    echo "    x     Exit shell script "
    read -p " Enter one of  k  d  x    or press return:  " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[kK]$ || "$REPLY" == "" ]]; then
      echo " *** install.sh: Keeping configuation and deleting old installation at ${INSTALL_DIR} "
      ls -l
      rm -Rf ${INSTALL_DIR}/${GIT_BRANCH}.zip
      rm -Rf ${INSTALL_DIR}/${GIT_BRANCH}.zip.*
      rm -Rf ${INSTALL_DIR}/${GIT_REPO}-${GIT_BRANCH}
    fi
    if [[ $REPLY =~ ^[dD]$ ]]; then
      echo " *** install.sh: Deleting configuration and installation at ${INSTALL_DIR} "
      ls -l
      rm -Rf ${INSTALL_DIR}/${GIT_BRANCH}.zip
      rm -Rf ${INSTALL_DIR}/${GIT_BRANCH}.zip.*
      rm -Rf ${INSTALL_DIR}/${GIT_REPO}-${GIT_BRANCH}
      rm -Rf ${INSTALL_DIR}/generated-conf-file.sh
    fi
    if [[ $REPLY =~ ^[xX]$ ]]; then
      echo " *** install.sh: Exiting script "
      exit
    fi
  else
    echo "*** install.sh: I want to make new installation directory at ${INSTALL_DIR} "
    read -p "Proceed with creating a new installation directory at ${INSTALL_DIR}? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
    mkdir -p ${INSTALL_DIR}
  fi
}



### todo: check concepts, probably deprecated partially
### check for what we can reuse
doInstallWithWGET()
{
  echo ""
  echo "*** install.sh: I am in directory ${PWD} and want to start downloading ${GIT_BRANCH}.zip ..."
  read -p "Proceed with downloading ${GIT_BRANCH}.zip ? [y/N] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
  wget --directory-prefix=${MAIN_DIR} https://github.com/{$GIT_OWNER}/${GIT_REPO}/archive/refs/heads/${GIT_BRANCH}.zip
  unzip -d ${MAIN_DIR} ${MAIN_DIR}/${GIT_BRANCH}.zip
  echo ""
  echo "DONE downloading ${GIT_BRANCH}.zip "

  # ensure presence of a configuration file
  if [ -f ${MAIN_DIR}/generated-conf-file.sh ]; then
    echo "*** quick-install.sh: Found an existing configuration file at ${MAIN_DIR}/generated-conf-file.sh"
    echo "    Shall I recreate a configuration from interactive questions ?"
    echo "    k     Keep configuration [DEFAULT: press return]"
    echo "    r     recreate configuration from interactive questions "
    read -p "Enter one of  k  r    or press return:  " -n 1 -r
    echo    # (optional) move to a new line
    if [[ $REPLY =~ ^[Kk]$ || "$REPLY" == "" ]]; then
      echo "*** install.sh: Reusing existing configuration file ${MAIN_DIR}/generated-conf-file.sh"
    fi
    if [[ $REPLY =~ ^[Rr]$ ]]; then
      echo "*** install: Recreating a new configuration file at ${MAIN_DIR}/generated-conf-file.sh"
      source ${MAIN_DIR}/${GIT_REPO}-${GIT_BRANCH}/bin/make-conf.sh
    fi
  else
    # did not find a configuration file: generate one
    echo "*** install.sh: Did not find a configuration file at ${MAIN_DIR}/generated-conf-file.sh and is creating one"
    source ${MAIN_DIR}/${GIT_REPO}-${GIT_BRANCH}/bin/make-conf.sh
  fi

  printf "*** install.sh: Generating throw-away secrets for the new installation..."
  mkdir ${MAIN_DIR}/${GIT_REPO}-${GIT_BRANCH}/private
  openssl rand -base64 16 > ${MAIN_DIR}/${GIT_REPO}-${GIT_BRANCH}/private/mysql-root-password.txt
  openssl rand -base64 16 > ${MAIN_DIR}/${GIT_REPO}-${GIT_BRANCH}/private/mysql-backup-password.txt
  chmod 700 ${MAIN_DIR}/${GIT_REPO}-${GIT_BRANCH}/private
  chmod 700 ${MAIN_DIR}/${GIT_REPO}-${GIT_BRANCH}/private/mysql-root-password.txt
  chmod 700 ${MAIN_DIR}/${GIT_REPO}-${GIT_BRANCH}/private/mysql-backup-password.txt
  printf "DONE\n\n"

  printf "*** install.sh: Preparing local directory for certificates..."
  mkdir -p ${MAIN_DIR}/KEYS-AND-CERTIFICATES
  chmod 700 ${MAIN_DIR}/KEYS-AND-CERTIFICATES
  printf "DONE\n\n"

  #### THIS NOT YEt !!!!!
  # now kick-off installation routine
  # printf "*** install.sh: Now starting installation routine install-dante.sh..."
  # source ${MAIN_DIR}/${GIT_REPO}-${GIT_BRANCH}/install-dante.sh
}