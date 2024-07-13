#!/bin/bash

# The only task is to signal to the caller (lap-entrypoint.sh) to shut down the service

source /home/dante/dantescript/common-defs.sh

export RETURN_VALUE="shutdown"
