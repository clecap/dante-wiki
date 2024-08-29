#!/bin/bash

# Initialize system by picking up the inital contents from github

source /home/dante/dantescript/common-defs.sh



printf "${GREEN}*** THIS IS /dantescript/initial-xml-git.sh ***** ${RESET}"

printf "\n*** Adding initial contents..."
  installInitialFromGit Cat_DanteInitialContents
  installInitialFromGit Cat_DanteInitialCustomize 
  installInitialFromGit MediaWiki_DanteInitialContents
  installInitialFromGit MediaWiki_DanteInitialCustomize
  installInitialFromGit Test
printf "DONE\n"



#### TODO: below is rubbish since we have no $CONt7Sidebar !!!!!!!  and Main Page 


# main page and sidebar need a separate check in to show the proper dates; this also needs an --overwrite flag
printf "\n*** Checking in sidebar..."
   php ${MOUNT}/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite --prefix "MediaWiki:" $CONT/Sidebar
  exec 1>&1 2>&2
printf "DONE\n"

printf "\n*** Checking in MainPage..."
  php ${MOUNT}/${TARGET}/maintenance/importTextFiles.php --rc -s "Imported by wiki-init.sh" --overwrite  "$CONT/Main Page"
  exec 1>&1 2>&2
printf "DONE\n"

# Must do an update, since we have installed all kinds of extensions earlier
doMaintenanceUpdate

doPostImportMaintenance

touchLocalSettings


printf "\n\n*** /home/dante/dantescript/initial-xml-git.sh COMPLETED \n\n"