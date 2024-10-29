#!/bin/bash

mkdir -p dante/dist
mkdir -p dante/private
touch dante/private/configuration.sh

curl -fsSL -o dante/dist/docker-compose-development.yaml https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/composer/docker-compose-development.yaml
curl -fsSL -o dante/dist/run.sh    https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/dist/run.sh
curl -fsSL -o dante/dist/stop.sh   https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/dist/stop.sh
curl -fsSL -o dante/dist/get.sh    https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/dist/get.sh

chmod 755 dante/dist/run.sh
chmod 755 dante/dist/stop.sh
chmod 755 dante/dist/get.sh

chmod 700 dante/private

docker pull clecap/dante-wiki:latest
docker tag clecap/dante-wiki:latest dante-wiki:latest