#!/bin/bash

# pushes all the work done locally inside of the volume to github.com/clecap/dante-delta




abort()
{
  printf "%b" "\e[1;31m *** PUSHING DANTE DELTA WAS ABORTED *** \e[0m"
  exit 1
}
set -e                                  # abort execution on any error
trap 'abort' EXIT                       # call abort on EXIT

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# navigating from DIR to the wiki directory where we collect the files
WIKI=${DIR}/../content/wiki-dir

# the local git we use for all of this
GIT_DIR=.danteGit

##
## Define what we have under git control - EDIT THE FILE MENTIONED BELOW -
##

source ${DIR}/git-files-EDIT-THIS-FILE.sh

printf "\n*** Changing to directory ${WIKI} "
cd ${WIKI}
printf " ... DONE\n\n"

 

if [ -d "$GIT_DIR" ]; then
  printf "*** Git directory ${GIT_DIR} already exists ... DONE"
else
  printf "*** Git directory ${GIT_DIR} does not exist, initializing and setting branchXXX YYYYYYYYY \n"
  git --git-dir=.danteGit init 
  printf " DONE "
fi

 
git --git-dir=$GIT_DIR config --local advice.addIgnoredFile false
for name in ${MY_FILES[@]}
do
  printf "*** Adding file to git: ${name}"
  git --git-dir=$GIT_DIR add  -f ${name}
  printf " ... DONE\n"
done

exit

printf "Working on directories: ${MY_DIRECTORIES}\n"

# need to cd and do an add . since this is the git way to do it
for name in ${MY_DIRECTORIES[@]}
do
  printf "*** Adding complete directory to git: ${name}\n"
  cd ${WIKI}/${name}
  git --git-dir=$GIT_DIR add -f .
done
git config advice.addIgnoredFile true


printf "*** Now commiting:\n"
git --git-dir=$GIT_DIR commit -m "Commit from git-push-delta.sh"
printf "DONE: Commiting\n\n"

printf "*** Pushing to upstream\n"
git --git-dir=$GIT_DIR push -f --set-upstream origin master --verbose
printf "DONE pushing to upstream\n\n"


printf "%b" "\e[1;32m PUSH TO DANTE DELTA COMPLETED \e[0m \n"

trap : EXIT         # switch trap command back to noop (:) on EXIT
