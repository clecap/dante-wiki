#!/bin/bash

# clone parsifal from branch dante

BRANCH=dante

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WIKI=${DIR}/../content/wiki-dir

printf "\n\n__________ installParsifal.sh __________\n\n"

# go to extensions directory
cd ${WIKI}/extensions

# remove Parsifal in case it is there
printf "*** Removing preexisting Parsifal to ensure clean start ... "
rm -Rf ${WIKI}/extensions/Parsifal
printf "DONE removing\n\n"

printf "*** Cloning Parsifal from branch $BRANCH ... "
git clone --branch $BRANCH https://github.com/clecap/Parsifal
printf "DONE cloning branch $BARNCH of Parsifal\n\n"

printf "\033[31m completed \033[0m \n"