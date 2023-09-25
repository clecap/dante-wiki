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

# pushes all the work done locally since the last 

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WIKI=${DIR}/../content/wiki-dir

printf "*** Adding files:\n"
cd ${WIKI}/extensions/Parsifal
git add . --verbose
printf "DONE: Adding files\n\n"

printf "\n*** Now commiting:\n"
git commit -m "Commit from git-push-to-parsifal.sh"
printf "DONE commiting\n\n"


printf "*** Now pushing to upstream\n"
git push -u --verbose
printf "DONE pushing to upstream\n\n"

printf "%b" "\e[1;32m PUSH TO PARSIFAL COMPLETED \e[0m \n"

trap : EXIT         # switch trap command back to noop (:) on EXIT
