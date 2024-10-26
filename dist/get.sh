#!/bin/bash

curl -fsSLO https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/composer/docker-compose-development.yaml
curl -fsSLO https://raw.githubusercontent.com/clecap/dante-wiki/HEAD/dist/run.sh
mkdir private
chmod 700 private
touch private/configuration.sh
docker pull clecap/dante-wiki:latest