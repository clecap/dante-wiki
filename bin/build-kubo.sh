#!/bin/bash

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TOP_DIR=${DIR}/.. 

# read in the library file for our shell
source $DIR/library.sh

set -euxo pipefail
trap 'abort' ERR

IMAGE_NAME="kubo-image"
IMAGE_TAG=mytag

# find this on https://github.com/ipfs/kubo/releases
KUBO_VER=v0.43.1

printf "\n$GREEN---Building kubo image $RESET\n"
# The Dockerfile clones the kubo source of release KUBO_VER itself
# --pull: always use the latest base images
docker build --pull --progress=plain -t "$IMAGE_NAME:$IMAGE_TAG" \
    --build-arg KUBO_VER="$KUBO_VER" \
    "$TOP_DIR/images/kubo/src"
ok "$GREEN---DONE$RESET"


CONTAINER_NAME=kubo
VOLUME_NAME=kubo-data

printf "\n$GREEN---Starting kubo container $RESET\n"
# remove an old container of the same name, if any
docker rm -f "$CONTAINER_NAME" 2> /dev/null || true

# -d:              run in background
# --restart:       restart after crash or reboot, unless stopped by hand
# -v:              named volume keeps the IPFS repository across container restarts
# -p 4002:4001:    swarm port (TCP/UDP), public for peer connections; host port 4002
#                  because 4001 is already in use on the host
# -p 127.0.0.1:... API (5001) and gateway (8080) only reachable from this host
docker run -d --name "$CONTAINER_NAME" --restart unless-stopped \
    -v "$VOLUME_NAME":/data/ipfs \
    -p 4002:4001 -p 4002:4001/udp \
    -p 127.0.0.1:5002:5001 \
    -p 127.0.0.1:8082:8080 \
    "$IMAGE_NAME:$IMAGE_TAG"
ok "$GREEN---DONE$RESET"

