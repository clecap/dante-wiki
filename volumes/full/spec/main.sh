#!/bin/bash


# manually edited file while working on script-library.sh

# get directory where this script resides, wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR="${DIR}/../../../"


source script-library.sh


minimalInitialContents
