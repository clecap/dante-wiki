#!/bin/sh

# generic entrypoint.sh of ssh docker, may be overwritten by subsequent docker layers
# NOTE: This design decision is usefull for ssh, since ssh will not remain the only layer as it provides no service after all

# call the specific entrypoint of ssh docker
source ssh-entry.sh

echo "entrypoint.sh: Sleeping for infinity to keep docker container alive..."
sleep infinity
echo "entrypoint.sh: Finished sleeping. This should not happen"