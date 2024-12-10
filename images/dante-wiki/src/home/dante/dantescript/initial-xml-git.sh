#!/bin/bash

# Initialize system by picking up the inital contents from github

source /home/dante/dantescript/common-defs.sh

trap 'warn' ERR

printf "${GREEN}*** THIS IS /dantescript/initial-xml-git.sh ***** ${RESET}"

printf "\n*** Adding initial contents..."
  installInitialFromGit Cat_DanteInitialContents
  installInitialFromGit Cat_DanteInitialCustomize 
  installInitialFromGit MediaWiki_DanteInitialContents
  installInitialFromGit MediaWiki_DanteInitialCustomize
  installInitialFromGit Test
printf "DONE\n"



# Must do an update, since we have installed all kinds of extensions earlier
doMaintenanceUpdate
doPostImportMaintenance
touchLocalSettings

printf "\n\n*** /home/dante/dantescript/initial-xml-git.sh COMPLETED \n\n"