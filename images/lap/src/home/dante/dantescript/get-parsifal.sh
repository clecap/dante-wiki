#!/bin/bash

source /home/dante/dantescript/common-defs.sh

PARSIFAL_BRANCH=dante

##
## Install Parsifal development version
##


if [ -d "$MOUNT/$TARGET/extensions/Parsifal/.git" ]; then
    printf "\n*** get-parsifal.sh: Git directory ${MOUNT}/$TARGET/.git already exists ... doing a PULL \n"
      git -C ${MOUNT}/${TARGET} pull origin ${BRANCH} ;       exec 1>&1 2>&2
    printf "DONE"
  else
    printf "\n*** get-parsifal.sh: Cloning Parsifal from branch $PARSIFAL_BRANCH into ${MOUNT}/${TARGET}/extensions... \n"
      git clone --depth 1 --branch $PARSIFAL_BRANCH https://github.com/clecap/Parsifal ${MOUNT}/$TARGET/extensions/Parsifal ;      exec 1>&1 2>&2
    printf "DONE get-parsifal.sh_ cloning branch $BRANCH of Parsifal\n"
fi

################## TODO: we must ensure that this leads to an error / ABORT if the branch does not exist 
################ TODO: we need to get a clear abort in numersou situations - and TODO clean up the existin live area before filling it in !!!!!!
######## CAVE not delete too much !!!!!
