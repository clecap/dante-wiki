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

printf "\n*** Changing to directory ${WIKI} ... "
cd ${WIKI}
printf "DONE\n\n"

printf "*** Adding all files:\n"
git add . --verbose
printf "DONE: Adding files\n\n"

printf "\n*** Commiting:\n"
git commit -m "Commit from git-push-to-parsifal.sh"
printf "DONE commiting\n\n"

printf "*** Pushing to upstream\n"
git push -u --verbose
printf "DONE pushing to upstream\n\n"

printf "%b" "\e[1;32m PUSH TO PARSIFAL COMPLETED \e[0m \n"

trap : EXIT         # switch trap command back to noop (:) on EXIT
