#!/bin/bash

# Prepares the deployment for a new version of DanteWiki by making a copy from a running instance
# inside of the development environment
#
# Another approach would be a fresh installation directly from the githubs.
#

# get directory where this script resides, wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR="${DIR}/../"

PRODUCTION=${TOP_DIR}/../dante-wiki-production
VOLUME=${TOP_DIR}/../dante-wiki-volume

printf "\n----- STEP 1: Prepare the VOLUME\n\n"

printf "*** Clean the directory ${VOLUME} which we will be using as copy target"
rm -Rf    ${VOLUME}
printf "\nDONE cleaning old directory\n\n"

printf "*** Making new directory\n"
mkdir -p  ${VOLUME}
cd        ${VOLUME}
mkdir -p ${VOLUME}/wiki-dir
cp -R ${TOP_DIR}/volumes/full/content/wiki-dir ${VOLUME}/

### removing stuff not really wanted (which should also be mentioned in .gitignore)
rm -Rf ${VOLUME}/wiki-dir/parsifal-cache/*
rm -Rf ${VOLUME}/wiki-dir/images/*
rm -f  ${VOLUME}/wiki-dir/LocalSettings.php
rm -f  ${VOLUME}/wiki-dir/mediawiki-PRIVATE.php
rm -Rf ${VOLUME}/wiki-dir/.git
rm -Rf ${VOLUME}/wiki-dir/extensions/Parsifal/.git
rm -Rf ${VOLUME}/wiki-dir/extensions/Parsifal/tests/*
rm -Rf ${VOLUME}/wiki-dir/extensions/Parsifal/formats_latex/*.fmt
rm -Rf ${VOLUME}/wiki-dir/extensions/Parsifal/formats_latex/*.fls
rm -Rf ${VOLUME}/wiki-dir/extensions/Parsifal/formats_latex/*.log
rm -Rf ${VOLUME}/wiki-dir/extensions/Parsifal/formats_pdflatex/*.fmt
rm -Rf ${VOLUME}/wiki-dir/extensions/Parsifal/formats_pdflatex/*.fls
rm -Rf ${VOLUME}/wiki-dir/extensions/Parsifal/formats_pdflatex/*.log
#
rm -Rf ${VOLUME}/wiki-dir/extensions/DanteLinks/DANTELINKS-LOGFILE
rm -Rf ${VOLUME}/wiki-dir/extensions/DanteTree/LOGFILE
rm -Rf ${VOLUME}/wiki-dir/extensions/DantePresentations/endpoints/ENDPOINT_LOG
rm -Rf ${VOLUME}/wiki-dir/extensions/DantePresentations/LOGFILE
rm -Rf ${VOLUME}/wiki-dir/LOGFILE
rm -Rf ${VOLUME}/wiki-dir/extensions/Parsifal/log/*
#
rm -Rf ${VOLUME}/wiki-dir/HISTORY
rm -Rf ${VOLUME}/wiki-dir/tests
rm -Rf ${VOLUME}/wiki-dir/docs

# drawio is too large for the tar file - we must install it seperately in install-dante.sh
rm -Rf ${VOLUME}/wiki-dir/external-services/draw-io/

find ${VOLUME}/wiki-dir -name ".DS_Store" -delete

# removing .git subdirectories, since github would handle them via links and not via copy
# note that github would not even show them as subdirectories but rather as a special icon
# See: https://stackoverflow.com/questions/62056294/github-folders-have-a-white-arrow-on-them
find ${VOLUME}/wiki-dir -name ".git" -exec rm -Rf {} \;

# removing language files, which we do not need (keeping en and de)
cd ${VOLUME}/wiki-dir/languages/i18n/
find [a-c]*.json -exec rm {} \;
find [f-z]*.json -exec rm {} \;
cd ${VOLUME}/wiki-dir/languages/i18n/exif
find [a-c]*.json -exec rm {} \;
find [f-z]*.json -exec rm {} \;

printf "DONE making new directory\n\n"

# we must remove the gitignore which was in use for dante
rm ${VOLUME}/wiki-dir/.gitignore

BRANCH=master

printf "*** Making a local git and pushing to github\n"
cd ${VOLUME}
git init
cp ${TOP_DIR}/bin/gitignore-for-volume ${VOLUME}/.gitignore
git add .
git commit -m "Autocommit by make-deployment.sh"
git branch -M ${BRANCH}
git remote add origin https://github.com/clecap/dante-wiki-volume.git
git config http.postBuffer 524288000
git push -u -f --set-upstream origin master
printf "\n\n DONE"


printf "\n----- STEP 2: Prepare PRODUCTION scripts\n\n"

# make directories for some scripts, use the same path as in development repository
mkdir -p ${PRODUCTION}/images/lap/bin
mkdir -p ${PRODUCTION}/images/my-mysql/bin
mkdir -p ${PRODUCTION}/volumes/full/spec

# copy in some scripts
cp ${TOP_DIR}/images/lap/bin/run.sh ${PRODUCTION}/images/lap/bin/run.sh
cp ${TOP_DIR}/images/lap/bin/both.sh ${PRODUCTION}/images/lap/bin/both.sh
cp ${TOP_DIR}/images/my-mysql/bin/run.sh ${PRODUCTION}/images/my-mysql/bin/run.sh

cp ${TOP_DIR}/volumes/full/spec/script-library.sh ${PRODUCTION}/volumes/full/spec/script-library.sh
cp ${TOP_DIR}/volumes/full/spec/wiki-db-local-initialize.sh ${PRODUCTION}/volumes/full/spec/wiki-db-local-initialize.sh
cp ${TOP_DIR}/volumes/full/spec/inject-keys.sh ${PRODUCTION}/volumes/full/spec/inject-keys.sh

## push this to the correct repository
printf "*** Adding, commiting and pushing this to the repository ${PRODUCTION}\n"
cd $PRODUCTION
git add .
git commit -m "From development git and force-pushed into dante-wiki-production git by make-deployment.sht"
git push --force

printf "DONE Production\n"
