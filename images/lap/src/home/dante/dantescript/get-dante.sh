#!/bin/bash



# the name of the branch to which we will clone
BRANCH=master

# the remote repository
REMOTE_REPO=https://github.com/clecap/dante-delta.git



printf "\n*** Initialize a git...\n"
  git init ${MOUNT}/${TARGET}
printf "DONE"

printf "\n*** Initialize a git...\n"
  git -C ${MOUNT}/${TARGET} remote add origin https://github.com/clecap/Parsifal.git
printf "DONE"

printf "\n*** Initialize a git...\n"
  git -C ${MOUNT}/${TARGET} fetch --depth 1 origin ${BRANCH}
printf "DONE"

printf "\n*** Initialize a git...\n"
  git -C ${MOUNT}/${TARGET} checkout -t origin/${BRANCH}
printf "DONE"






#printf "\n*** Changing to directory ${WIKI} ... "
#cd ${WIKI}
#printf "DONE\n\n"


#if [ -d "$MOUNT/$TARGET/.git" ]; then
#  printf "*** Git directory ${MOUNT}/$TARGET/.git already exists ... nothing DONE\n\n"
#else
#  printf "*** Git directory ${MOUNT}/$TARGET/.git does not exist, initializing and setting to branch master ... \n"
#  git --git-dir=${MOUNT}/$TARGET/.git  init --initial-branch=$BRANCH
#  git --git-dir=${MOUNT}/$TARGET/.git  remote add origin $REMOTE_REPO
#  printf "DONE initializing a git\n\n"
#fi

#printf "*** Fetching origin ... "
#  git --git-dir=${MOUNT}/${TARGET}/.git --work-tree=${MOUNT}/${TARGET} fetch origin
#printf "DONE fetching origin\n\n"

#printf "*** Hard reset on local git ... "
#  git --git-dir=${MOUNT}/${TARGET}/.git --work-tree=${MOUNT}/${TARGET}  reset --hard origin/master
#printf "DONE hard reset\n\n"

#printf "*** Pulling from ${BRANCH} ..."
#  git --git-dir=${MOUNT}/${TARGET}/.git --work-tree=${MOUNT}/${TARGET}  pull origin master
#printf "DONE pulling \n\n"

#printf "*** Push once to connect..."
#  git push --set-upstream origin master
#printf "DONE pushing once\n\n"


#printf "\033[1;32m completed git-pull-from-delta.sh \033[0m \n"

# trap : EXIT         # switch trap command back to noop (:) on EXIT