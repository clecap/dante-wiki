#!/bin/bash


if [ -e /home/dante/DONE-getDante ]; then
  printf "\n*** get-dante.sh already done\n"
  return 0
fi

source /home/dante/dantescript/common-defs.sh


trap 'errorTrap' ERR




#### TODO MUST ABORT COMPLETEL including upstream in case of error - also for some of the other dante scripts. and need an abotzt in lapentry-.sh
 
if [ -d "$MOUNT/$TARGET/.git" ]; then
    printf "\n*** get-dante.sh: Git directory ${MOUNT}$TARGET/.git already exists ... will be doing a PULL\n"
    GDIR=${MOUNT}${TARGET}/.git
    if ! git config --global --get-all safe.directory | grep -q "^${GDIR}$"; then
      printf "\n*** get-dante.sh needs to add directory $GDIR to safe.directory."
        git config --global --add safe.directory $GDIR
      printf "DONE adding to safe.directory"
    else
      printf "\n*** get-dante.sh already sees directory $DIR listed in safe.directory."
    fi
    printf "\n*** get-dante.sh: Setting git safe directory exception for ${MOUNT}${TARGET}...\n"
      # need to fix differences in userids of directory and of calling shell script, recommended by git itself
        git config --global --add safe.directory ${MOUNT}${TARGET}
    printf "DONE setting git safe directory exception\n"

    printf "\n*** get-dante.sh: Now pulling dante...\n"
      git -C ${MOUNT}/${TARGET} pull origin ${DANTE_BRANCH} ;       exec 1>&1 2>&2
    printf "DONE\n"
  else
    printf "\n*** get-dante.sh: Initialize a git...\n"
      git init ${MOUNT}/${TARGET} ;       exec 1>&1 2>&2
    printf "DONE\n"

    printf "\n*** get-dante.sh: remote add origin to dante-delta ...\n"
      git -C ${MOUNT}/${TARGET} remote add origin ${REMOTE_REPO_DANTE} ;       exec 1>&1 2>&2
    printf "DONE\n"

    printf "\n*** get-dante.sh: fetching dante-delta ...\n"
      git -C ${MOUNT}/${TARGET} fetch --depth 1 origin ${DANTE_BRANCH} ;       exec 1>&1 2>&2
    printf "DONE\n"

    printf "\n*** get-dante.sh:  checking out dante-delta ...\n"
      git -C ${MOUNT}/${TARGET} checkout -f -t origin/${DANTE_BRANCH};       exec 1>&1 2>&2
    printf "DONE\n"
## todo we might need to run update again, as the last time we did do so, the dante extensions had not been installed into LocalSettings.php yet
fi



configGitContainer


# The default operational mode after a get-dante.sh always is production mode
cp $MOUNT/$TARGET/DanteSettings-production.php $MOUNT/$TARGET/DanteSettings-used.php



##  installExtensionGithub https://github.com/wikimedia/mediawiki-extensions-DrawioEditor                   DrawioEditor REL1_39
## This extension is broken currently
##  Use my own version - see my mediawiki-extensions-DrawioEditor Patch
printf "\n*** get-dante.sh: Installing drawio extension ...\n"
  printf "   getting drawioeditor mediawiki extension..."
    /home/dante/dantescript/install-extension-github.sh  ${MOUNT}/${TARGET}  https://github.com/clecap/mediawiki-extensions-DrawioEditor                      DrawioEditor                master  ; exec 1>&1 2>&2
  printf "DONE\n"
  printf "   getting PATCH-UploadedFile.php..."
    curl -s -o ${MOUNT}/$TARGET/includes/libs/ParamValidator/Util/UploadedFile.php https://raw.githubusercontent.com/clecap/mediawiki-extensions-DrawioEditor/master/PATCH-UploadedFile.php            ; exec 1>&1 2>&2
  printf "DONE\n"
  printf "   getting PATCH-UploadedBase.php..."
    curl -s -o ${MOUNT}/$TARGET/includes/upload/UploadBase.php   https://raw.githubusercontent.com/clecap/mediawiki-extensions-DrawioEditor/master/PATCH-UploadBase.php                                ; exec 1>&1 2>&2
  printf "DONE\n"
printf "\nDONE installing drawio extension ...\n"
exec 1>&1 2>&2
printf "\n *** Installing drawio external service into target=${TARGET}\n"
  mkdir -p ${MOUNT}/${TARGET}/external-services/draw-io/
## TODO: below could be done better (not via culr but via clone with depth 0 or similar)
  curl -s -o ${MOUNT}/${TARGET}/external-services/dev.zip -L https://github.com/clecap/drawio/archive/refs/heads/dev.zip  ; exec 1>&1 2>&2
  unzip -o -q ${MOUNT}/${TARGET}/external-services/dev.zip -d ${MOUNT}/${TARGET}/external-services/draw-io/ ; exec 1>&1 2>&2
  rm ${MOUNT}/${TARGET}/external-services/dev.zip ; exec 1>&1 2>&2
printf "DONE installing drawio external service\n"
exec 1>&1 2>&2     


#   inject only, after LocalSettings.php has been generated
if [ -f "$MOUNT/$TARGET/LocalSettings.php" ]; then
    printf "\n*** get-dante.sh:  connecting to Mediawiki via an injection into LocalSettings.pgp ...\n"
    cat <<EOF >> ${MOUNT}/$TARGET/LocalSettings.php
###
### Automagically injected by volume cmd.sh 
###
require_once ("DanteSettings.php"); 
EOF
    printf "DONE"
  else
    printf "\n*** get-dante.sh: no LocalSettings.php found, cannot inject, maybe later\n" ;
fi

exec 1>&1 2>&2

sudo touch /home/dante/DONE-getDante

trap - ERR

printf "${GREEN}*** DONE get-dante.sh${RESET}"git push origin ma


