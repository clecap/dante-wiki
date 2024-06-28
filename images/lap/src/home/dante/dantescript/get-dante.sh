#!/bin/bash

source /home/dante/dantescript/common-defs.sh

#### TODO MUST ABORT COMPLETEL including upstream in case of error - also for some of the other dante scripts. and need an abotzt in lapentry-.sh

if [ -d "$MOUNT/$TARGET/.git" ]; then
    printf "\n*** get-dante.sj: Git directory ${MOUNT}/$TARGET/.git already exists ... doing a PULL \n"
      git -C ${MOUNT}/${TARGET} pull origin ${DANTE_BRANCH} ;       exec 1>&1 2>&2
    printf "DONE"
  else
    printf "\n*** get-dante.sh: Initialize a git...\n"
      git init ${MOUNT}/${TARGET} ;       exec 1>&1 2>&2
    printf "DONE"

    printf "\n*** get-dante.sh: remote add origin to dante-delta ...\n"
      git -C ${MOUNT}/${TARGET} remote add origin ${REMOTE_REPO_DANTE} ;       exec 1>&1 2>&2
    printf "DONE"

    printf "\n*** get-dante.sh: fetching dante-delta ...\n"
      git -C ${MOUNT}/${TARGET} fetch --depth 1 origin ${DANTE_BRANCH} ;       exec 1>&1 2>&2
    printf "DONE"

    printf "\n*** get-dante.sh:  checking out dante-delta ...\n"
      git -C ${MOUNT}/${TARGET} checkout -f -t origin/${DANTE_BRANCH};       exec 1>&1 2>&2
    printf "DONE"

#   inject only, after LocalSettings.php has been generated
    if [ -d "$MOUNT/$TARGET/LocalSettings.php" ]; then
      printf "\n*** get-dante.sh:  connecting to Mediawiki via an injection into LocalSettings.pgp ...\n"
      cat <<EOF >> ${MOUNT}/$TARGET/LocalSettings.php
###
### Automagically injected by volume cmd.sh 
###
require_once ("DanteSettings.php"); 
EOF
      printf "\n*** get-dante.sh: injecting ...\n"
    fi

## todo we might need to run update again, as the last time we did do so, the dante extensions had not been installed into LocalSettings.php yet

fi

# trap : EXIT         # switch trap command back to noop (:) on EXIT