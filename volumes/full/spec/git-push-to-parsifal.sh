#!/bin/bash

# (C) Clemens H. Cap 2023
# Push all work on Parsifal to Parsifal repository

abort()
{
  printf "%b" "\e[1;31m *** PUSHING PARSIFAL WAS ABORTED *** \e[0m"
  exit 1
}
set -e                                  # abort execution on any error
trap 'abort' EXIT                       # call abort on EXIT


# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

##
## CONFIGURATION of this script
##

# the directory from which we push all the work
WIKI=${DIR}/../content/wiki-dir/extensions/Parsifal

# the remote repository
REMOTE_REPO=https://github.com/clecap/Parsifal.git

# the name of the branch to which we push
BRANCH=dante

##
## END configuration
##

printf "\n*** Changing to directory ${WIKI} ... "
cd ${WIKI}
printf "DONE\n\n"

if [ -d ".git" ]; then
  printf "*** Git directory .git already exists ... nothing DONE\n\n"
else
  printf "*** Git directory .git does not exist, initializing and setting to branch ${BRANCH} ... \n"
  git init --initial-branch=$BRANCH
  git remote add origin $REMOTE_REPO
  printf "DONE\n\n"
fi

printf "*** Adding all files:\n"
git add . --verbose
printf "DONE: Adding files\n\n"

printf "\n*** Commiting:\n"
git commit -m "Commit from git-push-to-parsifal.sh"
printf "DONE commiting\n\n"

#
# NOTE: we can add --force below to force upstream push
#

printf "*** Pushing to upstream\n"
git push --verbose --set-upstream origin dante
printf "DONE pushing to upstream\n\n"

printf "%b" "\e[1;32m PUSH TO PARSIFAL COMPLETED \e[0m \n"

trap : EXIT         # switch trap command back to noop (:) on EXIT
