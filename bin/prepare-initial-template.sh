#!/bin/bash



# Prepare an initial template


# get directory where this script resides, wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR="${DIR}/../../../"

printf "\n\n*** reading in the script library..."
  source ${TOP_DIR}/volumes/full/spec/script-library.sh
printf "DONE\n\n"


LAP_CONTAINER=
INITIAL_TEMPLATE=initial-volume

cleanUpDocker ${LAP_CONTAINER} ${INITIAL_TEMPLATE}