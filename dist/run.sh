#!/bin/bash

# TODO: USE branches in github and tags in docker hub !!!

# branch we are checking out from github
BRANCH=master

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

docker compose -f "$compose_file" up -d $TOP_DIR/composer/docker-compose-development.yaml database webserver-raw phpmyadmin
