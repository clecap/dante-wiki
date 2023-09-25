#!/bin/bash
#
# automatizes that portion of the development flow which must be done when we need to redo the volume construction into a single step
# to be sued from the vscod task manager
#
#


# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${DIR}/../../../volumes/full/spec/cmd.sh
${DIR}/../../../images/lap/bin/both.sh --cleandb my-test-db-volume  --dir full
${DIR}/../../../volumes/full/spec/git-pull-from-delta.sh
${DIR}/../../../volumes/full/spec/wiki-init.sh