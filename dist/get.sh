#!/bin/bash

printf "\nThis is dante-wiki/dist/get.sh version 2.3\n\n"  # As freshness check during development

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}
printf "TOP_DIR used is ${TOP_DIR}\n"
printf "DIR used is ${DIR}\n"

# CAVE: TOP_DIR in get is the manually generated directory into which we install  


mkdir -p ${TOP_DIR}/dist
mkdir -p ${TOP_DIR}/private
touch ${TOP_DIR}/private/configuration.sh

curl -fsSL -o ${TOP_DIR}/dist/docker-compose-development.yaml https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/composer/docker-compose-development.yaml
curl -fsSL -o ${TOP_DIR}/dist/run.sh    https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/dist/run.sh
curl -fsSL -o ${TOP_DIR}/dist/stop.sh   https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/dist/stop.sh
curl -fsSL -o ${TOP_DIR}/dist/clean.sh    https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/dist/clean.sh

chmod 755 ${TOP_DIR}/dist/*.sh

chmod 755 ${TOP_DIR}/private
chmod 644 ${TOP_DIR}/private/configuration.sh

docker pull clecap/dante-wiki:latest
docker tag clecap/dante-wiki:latest dante-wiki:latest