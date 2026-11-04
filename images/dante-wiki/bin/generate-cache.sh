#!/bin/bash

# generate a local docker image for the docker context

IMAGE_NAME=lap

TOP_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# version from the git tags, see doc/DEVELOPMENT-CI.md: v1.2.3, v1.2.3-4-gabc1234 after it, or only the commit hash
DANTE_VERSION=$(git -C "$TOP_DIR" describe --tags --always --match 'v[0-9]*.[0-9]*.[0-9]*' 2>/dev/null || echo "unknown")

echo "VERSION: $DANTE_VERSION"

echo ""
echo "BUILDING image with name ${IMAGE_NAME} from docker context at ${DIR}/../src"
echo ""

docker build --build-arg DANTE_VERSION="$DANTE_VERSION" -t ${IMAGE_NAME}:latest -t ${IMAGE_NAME}:${DANTE_VERSION} ${DIR}/../src

echo " "; echo "DONE" ; echo " "
