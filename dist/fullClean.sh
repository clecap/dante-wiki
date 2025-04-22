#!/bin/bash

# TODO: USE branches in github and tags in docker hub !!!

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

printf "CLEANING UP ABSOLUTELY EVERYTHING FROM DOCKER"

  docker system prune -a --volumes -f

printf "CLEANED UP"