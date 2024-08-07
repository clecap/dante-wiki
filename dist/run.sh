#!/bin/bash


# TODO: USE branches in github and tags in docker hub !!!

# branch we are checking out from github
BRANCH=master



mkdir -p volumes/mysql-init
curl -fsSL -o volumes/mysql-init/init.sh https://raw.githubusercontent.com/clecap/dante-wiki/$BRANCH/volumes/mysql-init/init.sh
chmod 755 volumes/mysql-init/init.sh

curl -fsSL -o docker-compose-production.yaml https://raw.githubusercontent.com/clecap/dante-wiki/$BRANCH/dist/docker-compose-production.yaml

docker-compose -f docker-compose-production.yaml down

docker-compose -f docker-compose-production.yaml up