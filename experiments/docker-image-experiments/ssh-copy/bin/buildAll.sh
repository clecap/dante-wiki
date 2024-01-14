#!/bin/bash

# get directory this shell is running in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${DIR}/prepare.sh
${DIR}/generate.sh
${DIR}/run.sh
${DIR}/postpare.sh
