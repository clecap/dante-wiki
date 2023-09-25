#!/bin/bash

# Clone clecap/dante-delta from github

abort()
{
  printf "%b" "\e[1;31m *** CLONING FROM DELTA WAS ABORTED *** \e[0m"
  exit 1
}

set -e                                  # abort execution on any error
trap 'abort' EXIT                       # call abort on EXIT


# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

##
## CONFIGURATION of this script
##

# the wiki directory into which we clone the files
WIKI=${DIR}/../content/wiki-dir

# the name of the branch to which we will clone
BRANCH=master

# the local git we use for all of this
GIT_DIR=${WIKI}/.git

# the remote repository
REMOTE_REPO=https://github.com/clecap/dante-delta.git


printf "\n*** Changing to directory ${WIKI} ... "
cd ${WIKI}
printf "DONE\n\n"

if [ -d "$GIT_DIR" ]; then
  printf "*** Git directory ${GIT_DIR} already exists ... nothing DONE\n\n"
else
  printf "*** Git directory ${GIT_DIR} does not exist, initializing and setting to branch master ... \n"
  git --git-dir=$GIT_DIR  init --initial-branch=$BRANCH
  git --git-dir=$GIT_DIR  remote add origin $REMOTE_REPO
  git --git-dir=$GIT_DIR  config --local core.excludesfile ${DIR}/../../spec/git-ignore-for-delta       # configure this git to use spec/.gitignore
  printf "DONE initializing a git\n\n"
fi

printf "*** Fetching origin ... "
git --git-dir=$GIT_DIR --work-tree=${WIKI}  fetch origin
printf "DONE fetching origin\n\n"

printf "*** Hard reset on local git ... "
 
git --git-dir=$GIT_DIR --work-tree=${WIKI}  reset --hard origin/master

printf "*** Pulling from ${BRANCH} ..."
git --git-dir=$GIT_DIR --work-tree=${WIKI}  pull origin master
printf "DONE pulling \n\n"

printf "\033[1;32m completed git-pull-from-delta.sh \033[0m \n"

trap : EXIT         # switch trap command back to noop (:) on EXIT