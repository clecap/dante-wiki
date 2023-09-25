#!/bin/bash

# install a working / editin version of parsifal branch dante

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WIKI=${DIR}/../content/wiki-dir

printf "\n\n__________ installParsifal.sh __________\n\n"

# go to extensions directory
cd ${WIKI}/extensions

# remove Parsifal if it is still there
printf "*** installParsifal.sh: removing preexisting Parsifal to ensure clean start..."
rm -Rf ${WIKI}/extensions/Parsifal
printf "DONE removing\n\n"

printf "*** installParsifal.sh: cloning dante branch..."
git clone --branch dante https://github.com/clecap/Parsifal
printf "DONE cloning dante branch of Parsifal\n\n"

printf "\033[31m completed installParsifal.sh \033[0m \n"