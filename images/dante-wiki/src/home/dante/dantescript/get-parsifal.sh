#!/bin/bash

source /home/dante/dantescript/common-defs.sh

##
## Install Parsifal development version
##

exec 1>&1 2>&2

if [ -d "$MOUNT/$TARGET/extensions/Parsifal/.git" ]; then
    printf "\n*** get-parsifal.sh: Git directory ${MOUNT}/$TARGET/extensions/Parsifal/.git already exists ... doing a PULL \n"
      git -C ${MOUNT}/${TARGET} pull origin ${PARSIFAL_BRANCH} ;       exec 1>&1 2>&2
    printf "DONE doing a pull\n"
  else
    printf "\n*** get-parsifal.sh: Cloning Parsifal from branch $PARSIFAL_BRANCH into ${MOUNT}/${TARGET}/extensions... \n"
      git clone --depth 1 --branch $PARSIFAL_BRANCH https://github.com/clecap/Parsifal ${MOUNT}/$TARGET/extensions/Parsifal ;      exec 1>&1 2>&2
    printf "DONE get-parsifal.sh_ cloning branch $BRANCH of Parsifal\n"
fi

printf "*** Making parsifal lock directory\n\n"
  mkdir -p /var/lock/parsifal
printf "\nDONE\n\n"

