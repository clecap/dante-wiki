#!/bin/bash

#
# Install the vscodium extensions recommended for development of dantewiki
#

NAME=file-action-0.0.31.vsix

rm -f /tmp/${NAME}

wget https://raw.githubusercontent.com/clecap/file-action/main/${NAME}  -O /tmp/${NAME}

codium --install-extension /tmp/${NAME}

rm -f /tmp/${NAME}