#!/bin/bash

# pushes all the work done locally since the last 

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WIKI=${DIR}/../content/wiki-dir

cd ${WIKI}/extensions/Parsifal
git add .

# ncom is the non comment commit which I use in my system 
echo "*** Commit"
git ncom
echo ""


echo "*** Push to upstream"
git push -u
echo ""




##
##
##