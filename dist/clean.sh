#!/bin/bash

# TODO: USE branches in github and tags in docker hub !!!

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

printf "CLEANING UP"

docker container stop dante-wiki-container
docker container stop dante-mariadb-container
docker container rm dante-wiki-container
docker container rm dante-mariadb-container


printf "CLEANED UP"