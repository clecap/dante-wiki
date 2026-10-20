#!/bin/bash

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

source $DIR/library.sh

set -e
trap 'abort' ERR

cook dante-wiki-container


## BEWARE: Do not upload as the images contain our secret tokens und more !!!!!

# cooked_to_DockerHub
# cooked_to_GitHub