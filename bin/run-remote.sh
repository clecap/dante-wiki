#!/bin/bash

# runs all steps to run dante as installed on a remote machine

# get directory where this script resides, wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TOP_DIR="${DIR}/../"

${TOP_DIR}/bin/build-volume-template.sh

${TOP_DIR}volumes/bin/add-dir.sh full sample-volume /

${TOP_DIR}images/lap/bin/both.sh --db my-test-db-volume --vol sample-volume

sleep 3
# wait for DB to come up ....

${TOP_DIR}volumes/full/spec/wiki-init.sh