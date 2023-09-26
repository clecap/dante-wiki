#!/bin/bash

# Pulls all the work from clecap/dante-delta into this directory

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WIKI=${DIR}/../content/wiki-dir

# go to main directory of wiki
cd ${WIKI}

printf "\n_____________________\n"

# ensuring we are starting from a clean slate
printf "*** git-pull-from-delta.sh: Removing git directory..."
rm -Rf .git
printf "DONE removing git directory\n\n"

# initialize a git there
printf "*** git-pull-from-delta.sh: git-pull-from-delta.sh: Initializing a git..."
git init --initial-branch=master                                        # initialize; silence hint on other branch names
git config --local core.excludesfile ${DIR}/../../spec/.gitignore       # configure this git to use spec/.gitignore
printf "DONE initializing a git\n\n"

# connect to the dante delta repository
printf "*** git-pull-from-delta.sh: adding github as remote..."
git remote add origin https://github.com/clecap/dante-delta.git
printf "DONE adding github as remote\n\n"

printf "*** git-pull-from-delta.sh: fetching origin..."
git fetch origin
printf "DONE fetching origin\n\n"

#printf "*** git-pull-from-delta.sh: doing a hard reset on local git and pulling from master
git reset --hard origin/master
git pull origin master
git push --set-upstream origin master
#printf "DONE hard reset\n\n"
  


printf "\033[31m completed git-pull-from-delta.sh \033[0m \n"