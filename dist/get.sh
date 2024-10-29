#!/bin/bash

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

mkdir -p ${TOP_DIR}/dist
mkdir -p ${TOP_DIR}/private
touch ${TOP_DIR}/private/configuration.sh

curl -fsSL -o ${TOP_DIR}/dist/docker-compose-development.yaml https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/composer/docker-compose-development.yaml
curl -fsSL -o ${TOP_DIR}/dist/run.sh    https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/dist/run.sh
curl -fsSL -o ${TOP_DIR}/dist/stop.sh   https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/dist/stop.sh
curl -fsSL -o ${TOP_DIR}/dist/get.sh    https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/dist/get.sh

chmod 755 ${TOP_DIR}/dist/run.sh
chmod 755 ${TOP_DIR}/dist/stop.sh
chmod 755 ${TOP_DIR}/dist/get.sh
chmod 600 ${TOP_DIR}/private/configuration.sh

chmod 600 ${TOP_DIR}/private

docker pull clecap/dante-wiki:latest
docker tag clecap/dante-wiki:latest dante-wiki:latest