#!/bin/bash

source ./global-names.sh

# Parse the command line
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 FAMILYNAME " >&2
  exit 1
fi

FAMILY_NAME=$1

aws ecs list-task-definitions --family-prefix ${FAMILY_NAME}