#!/bin/bash

source /home/dante/dantescript/common-defs.sh

PARSIFAL_BRANCH=dante

##
## Install Parsifal development version
##
printf "\n*** init.sh: Cloning Parsifal from branch $PARSIFAL_BRANCH into ${MOUNT}/${TARGET}/extensions... \n"
  git clone --depth 1 --branch $PARSIFAL_BRANCH https://github.com/clecap/Parsifal ${MOUNT}/$TARGET/extensions/Parsifal
  exec 1>&1 2>&2
printf "DONE cloning branch $BRANCH of Parsifal\n"


################## TODO: we must ensure that this leads to an error / ABORT if the branch does not exist 
################ TODO: we need to get a clear abort in numersou situations - and TODO clean up the existin live area before filling it in !!!!!!
######## CAVE not delete too much !!!!!
