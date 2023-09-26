#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 FAMILYNAME" >&2
  exit 1
fi
FAMILY_NAME=$1

export REPOSITORY_NAME="reposi-${FAMILY_NAME}"

if aws ecr describe-repositories --repository-names ${REPOSITORY_NAME} > /dev/null; then
  echo "*** Found repository: " ${REPOSITORY_NAME}
  export REPOSITORY_URI=`aws ecr describe-repositories --repository-names ${REPOSITORY_NAME} | jq -r '.repositories[0].repositoryUri' `
  echo "*** URI of repository just found is: " ${REPOSITORY_URI}
else
  echo "*** FATAL ERROR *** Did not find repository ${REPOSITORY_NAME}"
fi