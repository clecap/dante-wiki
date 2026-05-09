#!/bin/bash

# install shell script which downloads ${REPO} and uses the shellscripts from there to set up the system

MAIN_DIR="dante"    # Main directory on the machine into which we install, relative to the current directory
OWNER="clecap"      # Owner name of the github repository for the installation
REPO="dante-wiki"   # Github repository from which we will install
BRANCH="master"     # Branch which we will install

VERSION=1.52        # Version number, just for identification purposes

printf "\n"
printf "****************************\n"
printf "*** QUICK INSTALLER ${VERSION} ***\n"
printf "****************************\n\n" 


if [ -d ${MAIN_DIR} ]; then
  echo "*** quick-install.sh: Found an old installation directory at ${PWD}/${MAIN_DIR} "
  echo "    k     Keep configuration and keys, delete remaining installation [DEFAULT: press return]"
  echo "    d     Delete configuration, delete installation, keep keys "
  echo "    x     Exit shell script "
  read -p " Enter one of  k  d  x    or press return:  " -n 1 -r
  echo    # (optional) move to a new line
  if [[ $REPLY =~ ^[kK]$ || "$REPLY" == "" ]]; then
    echo " *** install.sh: Keeping configuation and deleting old installation at ${PWD}/${MAIN_DIR} "
    ls -l
    rm -Rf ${MAIN_DIR}/${BRANCH}.zip
    rm -Rf ${MAIN_DIR}/${BRANCH}.zip.*
    rm -Rf ${MAIN_DIR}/${REPO}-${BRANCH}
  fi
  if [[ $REPLY =~ ^[dD]$ ]]; then
    echo " *** install.sh: Deleting configuration and installation at ${PWD}/${MAIN_DIR} "
    ls -l
    rm -Rf ${MAIN_DIR}/${BRANCH}.zip
    rm -Rf ${MAIN_DIR}/${BRANCH}.zip.*
    rm -Rf ${MAIN_DIR}/${REPO}-${BRANCH}
    rm -Rf ${MAIN_DIR}/generated-conf-file.sh
  fi
  if [[ $REPLY =~ ^[xX]$ ]]; then
    echo " *** install.sh: Exiting script "
    exit
  fi
else
  echo "*** install.sh: I want to make new installation directory at ${PWD}/${MAIN_DIR} "
  read -p "Proceed with creating a new installation directory at ${PWD}/${MAIN_DIR}? [y/N] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
  mkdir -p ${MAIN_DIR}
fi


echo ""
echo "*** install.sh: I am in directory ${PWD} and want to start downloading ${BRANCH}.zip ..."
read -p "Proceed with downloading ${BRANCH}.zip ? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
wget --directory-prefix=${MAIN_DIR} https://github.com/{$OWNER}/${REPO}/archive/refs/heads/${BRANCH}.zip
unzip -d ${MAIN_DIR} ${MAIN_DIR}/${BRANCH}.zip
echo ""
echo "DONE downloading ${BRANCH}.zip "

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
    source ${MAIN_DIR}/${REPO}-${BRANCH}/bin/make-conf.sh
  fi
else
  # did not find a configuration file: generate one 
  echo "*** install.sh: Did not find a configuration file at ${MAIN_DIR}/generated-conf-file.sh and is creating one" 
   source ${MAIN_DIR}/${REPO}-${BRANCH}/bin/make-conf.sh
fi

printf "*** install.sh: Generating throw-away secrets for the new installation..."
mkdir ${MAIN_DIR}/${REPO}-${BRANCH}/private
openssl rand -base64 16 > ${MAIN_DIR}/${REPO}-${BRANCH}/private/mysql-root-password.txt
openssl rand -base64 16 > ${MAIN_DIR}/${REPO}-${BRANCH}/private/mysql-backup-password.txt
chmod 700 ${MAIN_DIR}/${REPO}-${BRANCH}/private
chmod 700 ${MAIN_DIR}/${REPO}-${BRANCH}/private/mysql-root-password.txt
chmod 700 ${MAIN_DIR}/${REPO}-${BRANCH}/private/mysql-backup-password.txt
printf "DONE\n\n"


printf "*** install.sh: Preparing local directory for certificates..."
mkdir -p ${MAIN_DIR}/KEYS-AND-CERTIFICATES
chmod 700 ${MAIN_DIR}/KEYS-AND-CERTIFICATES
printf "DONE\n\n"

#### THIS NOT YEt !!!!!
# now kick-off installation routine
# printf "*** install.sh: Now starting installation routine install-dante.sh..."
# source ${MAIN_DIR}/${REPO}-${BRANCH}/install-dante.sh