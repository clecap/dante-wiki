#!/bin/bash

printf "\n** Taking done configuration..."
docker-compose -f composer/docker-compose-development.yaml down 
printf "DONE"

printf "\n** Building image if necessary..."
docker build -t lap:latest ../images/lap/Dockerfile
printf "DONE"

printf "\n Starting up ..."
docker-compose  -f composer/docker-compose-development.yaml up 
printf "DONE"

if [ `uname` == "Darwin" ]; then 
  echo ""; echo "*** Attempting to start a local Chrome browser - this may fail"; echo "";
  open -a "Google Chrome"  http://localhost:${PORT_HTTP}/index.html
fi