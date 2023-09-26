#!/bin/bash

source ./global-names.sh

## export SUBNETS=`aws ec2 describe-subnets   --region ${REGION_ID} | jq  '.Subnets' | jq 'map(.SubnetId)' | jq 'join(", ")' -r ` 

### todo: make consistent and do not hardcode
EFS_AZN="eu-central-1a"


### SUBNET
echo __________________________________
echo -n "*** Look for a subnet with availabilityZone equal to ${EFS_AZN}"
export SUBNETS=`aws ec2 describe-subnets --region ${REGION_ID} | jq -r --arg EFS_AZN "${EFS_AZN}" '.Subnets | map(select(.AvailabilityZone==$EFS_AZN)) | .[0].SubnetId' `
echo " found: ${SUBNETS}"
echo