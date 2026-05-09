#!/bin/bash

# Install shell script 
# (1) cloes ${GIT_REPO} 
# (2) uses the shellscripts from there to set up the system, which could comprise two scenarios
#
# Scenario 1: We build the docker image locally
#
# Scenario 2: We pull the docker image from docker hub


##
## CONFIGURABLE PARAMETERS
##

## LOCAL configuration
MAIN_DIR="dante-operations"    # Main directory on the machine INTO which we install, relative to the current working directory

## GITHUB configuration
GIT_OWNER="clecap"             # Owner name of the github repository for the installation
GIT_REPO="dante-wiki"          # Github repository from which we will install
GIT_BRANCH="master"            # Branch which we will install

## DOCKERHUB configuration
DH_OWNER="clecap"
DH_REPO="dante-wiki"
DH_TAG="latest"


DH_PULL_SPEC="clecap@sha256:c48e8f5fb8d56b8b4870904cd78600f45130aaee7f30c58944185fffb517f158"


VERSION=1.56                   # Version number, just for identification purposes

##
## CALCULATED PARAMETERS
##

INSTALL_DIR="${PWD}/${MAIN_DIR}"

##
##
## DECLARATION of FUNCTIONS
##
##

printBanner() 
{
  printf "\n"
  printf "****************************\n"
  printf "*** QUICK INSTALLER ${VERSION} ***\n"
  printf "****************************\n\n" 
  printf "*\n"
  printf "* Running from current working directory ${PWD} \n"
  printf "* Will be installing into ${INSTALL_DIR} \n"
  printf "\n"
  read -p "Proceed ? [y/N] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
}


checkOldInstallation()  ###### TODO !!!
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


doInstallWithGIT()
{
  printf "*** install.sh: Will clone branch $GIT_BRANCH from https://github.com/$GIT_OWNER/$GIT_REPO.git to ${INSTALL_DIR}\n\n"
  read -p "Proceed with cloning? [y/N] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
  git clone --depth 1 --branch $GIT_BRANCH https://github.com/$GIT_OWNER/$GIT_REPO.git ${INSTALL_DIR}
}





##
##
## MAIN function
##
##

printBanner


if command -v git &>/dev/null; then
  echo "*** install.sh: git is installed ($(git --version))"
  doInstallWithGIT
#  ./composer/build-run-raw.sh
  source ${INSTALL_DIR}/composer/pull-run-raw.sh

else
  echo "*** install.sh: git is not installed. Please install git and re-run this script."
  exit 1
fi



