#!/bin/bash

# (C) Clemens H. Cap 2023
# Clone parsifal from github

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

# the directory into which we clone the files
WIKI=${DIR}/../content/wiki-dir

# the name of the branch to which we will clone
BRANCH=dante

printf "\n*** Changing to directory ${WIKI}/extensions ... "
cd ${WIKI}/extensions
printf "DONE\n\n"

printf "*** Removing preexisting Parsifal to ensure clean start ... "
rm -Rf ${WIKI}/extensions/Parsifal
printf "DONE removing\n\n"

printf "*** Cloning Parsifal from branch $BRANCH ... "
git clone --branch $BRANCH https://github.com/clecap/Parsifal
printf "DONE cloning branch $BARNCH of Parsifal\n\n"

printf "\033[1;32m completed \033[0m \n"

trap : EXIT         # switch trap command back to noop (:) on EXIT