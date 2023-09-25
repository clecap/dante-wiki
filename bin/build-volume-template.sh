#!/bin/bash

# get directory where this script resides, wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TOP_DIR="${DIR}/../"

rm -Rf ${TOP_DIR}/volumes/full/content

source ${TOP_DIR}/volumes/full/spec/cmd.sh
source ${TOP_DIR}/volumes/full/spec/git-pull-from-delta.sh
source ${TOP_DIR}/volumes/full/spec/git-clone-dante-from-parsifal.sh