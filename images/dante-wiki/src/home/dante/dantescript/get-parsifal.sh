#!/bin/bash

source /home/dante/dantescript/common-defs.sh

##
## Install Parsifal development version
##

printf "\n*** get-parsifal.sh \n"

set -e  # exit on error

if [ -d "$MOUNT/$TARGET/extensions/Parsifal/.git" ]; then
    printf "\n*** get-parsifal.sh: Git directory ${MOUNT}$TARGET/extensions/Parsifal/.git already exists ... will be doing a PULL \n"
    GDIR=${MOUNT}${TARGET}/extensions/Parsifal/.git
    if ! git config --global --get-all safe.directory | grep -q "^${GDIR}$"; then
      printf "\n*** get-parsifal.sh needs to add directory $GDIR to safe.directory."
        git config --global --add safe.directory $GDIR
      printf "DONE adding to safe.directory"
    else
      printf "\n*** get-parsifal.sh already sees directory $GDIR listed in safe.directory."
    fi
    printf "\n*** get-parsifal.sh: Now pulling Parsifal \n"
      git -C ${MOUNT}/${TARGET}/extensions/Parsifal pull origin ${PARSIFAL_BRANCH} ;       exec 1>&1 2>&2
    printf "DONE doing a pull\n"
  else
    printf "\n*** get-parsifal.sh: Cloning Parsifal from branch $PARSIFAL_BRANCH into ${MOUNT}/${TARGET}/extensions... \n"
      git clone --depth 1 --branch $PARSIFAL_BRANCH https://github.com/clecap/Parsifal ${MOUNT}/$TARGET/extensions/Parsifal ;      exec 1>&1 2>&2
    printf "DONE get-parsifal.sh_ cloning branch $BRANCH of Parsifal\n"
fi


set +e  # unset exit on error

