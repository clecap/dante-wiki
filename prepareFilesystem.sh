#!/bin/bash

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 NAME  [AVAILABILITY-ZONE(default eu-central-1a)]" >&2
  exit 1
fi
if [ "$#" -eq 1 ]; then
  FS_NAME=$1
  AVZN="eu-central-1a"
fi
if [ "$#" -eq 2 ]; then
  FS_NAME=$1
  AVZN=$2
fi
if [ "$#" -ge 3 ]; then
  echo "Usage: $0 NAME  [AVAILABILITY-ZONE(default eu-central-1a)]" >&2
  exit 1
fi



echo 
echo __________________________________
aws efs create-file-system  --creation-token ${FS_NAME} --tags "[{\"Key\":\"Name\", \"Value\":\"${FS_NAME}\"}]" \
  --performance-mode generalPurpose --throughput-mode bursting 
  --region ${REGION_ID} --availability-zone-name ${AVZN} | jq -r '.FileSystemId'

aws efs describe-file-systems --creation-token ${FS_NAME} | jq -r '.FileSystems | .[0] | .FileSystemId'

