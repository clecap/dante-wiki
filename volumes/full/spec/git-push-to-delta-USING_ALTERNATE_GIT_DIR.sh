#!/bin/bash

# collects all the work done on dante modifications inside of the volume $WIKI
# and described in file  git-files-EDIT-THIS-FILE.sh
# and pushes them to github.com/clecap/dante-delta
#
# NOTE: We use a separate git directory, since volume might have a git directory from other activities

abort()
{
  printf "%b" "\e[1;31m *** PUSHING DANTE DELTA WAS ABORTED *** \e[0m"
  exit 1
}

set -e                                  # abort execution on any error
trap 'abort' EXIT                       # call abort on EXIT

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


##
## CONFIGURATION of this script
##

# the wiki directory in which we collect the files
WIKI=${DIR}/../content/wiki-dir

# the name of the branch to which we will push upstream
BRANCH=master

# the local git we use for all of this
GIT_DIR=${WIKI}/.danteGit

# the remote repository
REMOTE_REPO=https://github.com/clecap/dante-delta.git

##
## Define what we have under git control - EDIT THE FILE MENTIONED BELOW -
##

source ${DIR}/git-files-EDIT-THIS-FILE.sh

##
##
##

printf "\n*** Changing to directory ${WIKI} ... "
cd ${WIKI}
printf "DONE\n\n"

if [ -d "$GIT_DIR" ]; then
  printf "*** Git directory ${GIT_DIR} already exists ... nothing DONE\n\n"
else
  printf "*** Git directory ${GIT_DIR} does not exist, initializing and setting to branch master ... \n"
  git --git-dir=$GIT_DIR init --initial-branch=$BRANCH
  git --git-dir=$GIT_DIR remote add origin $REMOTE_REPO
  git --git-dir=$GIT_DIR  config --local core.excludesfile ${DIR}/../../spec/git-ignore-for-delta    
  printf "DONE\n\n"
fi

#git --git-dir=$GIT_DIR config --local advice.addIgnoredFile false

printf "\n\n** Working on files:\n\n"
for name in ${MY_FILES[@]}
do
  printf "*** Adding file ${name} to $GIT_DIR ... "
  git --git-dir=$GIT_DIR --work-tree=${WIKI}   add -f ${name}
  printf "DONE\n"
done
printf "DONE working on files\n\n"

# need to cd and do an add . since this is the git way to do it
printf "\n** Working on directories: ${MY_DIRECTORIES}\n\n"
for name in ${MY_DIRECTORIES[@]}
do
  printf "*** Adding directory ${name} to $GIT_DIR ... "
  cd ${WIKI}/${name}
  git --git-dir=$GIT_DIR  --work-tree=${WIKI} add -f .
  printf "DONE\n"
done
printf "DONE working on directories\n\n"

git --git-dir=$GIT_DIR  --work-tree=${WIKI}  config --local advice.addIgnoredFile true

printf "*** Now commiting:\n"
  git --git-dir=$GIT_DIR  --work-tree=${WIKI}  commit -m "Commit from git-push-delta.sh"
printf "DONE: Commiting\n\n"

printf "*** Pushing to upstream\n"
  git --git-dir=$GIT_DIR  --work-tree=${WIKI}  push -f --set-upstream origin $BRANCH --verbose
printf "DONE pushing to upstream\n\n"

printf "%b" "\e[1;32m PUSH TO DANTE DELTA COMPLETED \e[0m \n"

trap : EXIT         # switch trap command back to noop (:) on EXIT
