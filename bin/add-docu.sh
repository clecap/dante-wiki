#!/bin/bash
#
# Generates the doxygen documentation of MediaWiki on demand and copies it into the running wiki container.
# Not part of the normal build / run workflow.
#
# Doxygen pulls in about 240 MB of LLVM / Clang libraries, so we do not want it in the wiki image.
# Instead we build a throwaway image DOCU_IMAGE on top of BASE_IMAGE which adds doxygen, generate the
# documentation there and stream it as tar archive into DOCU_DIR of the running container CONTAINER.
#
# Usage: bin/add-docu.sh

# get directory where this script resides wherever it is called from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# read in the library file for our shell
source $DIR/library.sh

set -e
set -o pipefail
trap 'abort' ERR

BASE_IMAGE=dante-wiki:latest                     # image with the MediaWiki source the documentation is generated from
DOCU_IMAGE=dante-wiki-docu:latest                # throwaway image: BASE_IMAGE plus doxygen
CONTAINER=dante-wiki-container                   # running wiki container which receives the documentation
TOP_PATH=/var/www/html/wiki-dir                  # MediaWiki installation directory, in image and container
DOCU_DIR=${TOP_PATH}/docs                        # mwdocgen.php writes into the subdirectory html of its --output
DOXYGEN_VERSION=1.9.8+ds-2.1                     # pinned like the other apt packages in images/dante-wiki/src/Dockerfile
                                                 # graphviz (dot, for the diagrams) is already in BASE_IMAGE

docker container inspect ${CONTAINER} > /dev/null 2>&1 || { printf "${ERROR}*** Container ${CONTAINER} is not running - EXITING${RESET}\n"; exit 1; }

printf "\n${GREEN}*** Building ${DOCU_IMAGE} from ${BASE_IMAGE} with doxygen ${DOXYGEN_VERSION}${RESET}\n"
docker build -t ${DOCU_IMAGE} - <<EOF
FROM ${BASE_IMAGE}
USER root
RUN apt-get update                                                                && \
    apt-get install -y --no-install-recommends doxygen=${DOXYGEN_VERSION}         && \
    rm -rf /var/lib/apt/lists/*
USER www-data
EOF
printf "${GREEN}DONE${RESET}\n"

# mwdocgen.php needs no database, but MediaWiki refuses to start without \$wgServer, and BASE_IMAGE has no
# LocalSettings.php (init.sh generates it at runtime) - so we hand it a stub.
# All progress output goes to stderr, since stdout carries the tar archive.
printf "\n${GREEN}*** Generating documentation in ${DOCU_IMAGE} and streaming it into ${CONTAINER}:${DOCU_DIR}/html${RESET}\n"
docker exec -u root ${CONTAINER} rm -rf ${DOCU_DIR}/html
docker run --rm --entrypoint "" ${DOCU_IMAGE} sh -c "
    set -e
    printf '<?php\n\$wgServer = \"http://localhost\";\n' > /tmp/LocalSettings.php
    cd ${TOP_PATH}
    php maintenance/run.php mwdocgen --conf /tmp/LocalSettings.php --output /tmp/docs --extensions --skins >&2
    tar -C /tmp/docs -cf - html
  " | docker exec -i -u www-data ${CONTAINER} tar -C ${DOCU_DIR} -xf -
printf "${GREEN}DONE${RESET}\n"

printf "\n${GREEN}*** Documentation is now in ${CONTAINER}:${DOCU_DIR}/html${RESET}\n\n"
