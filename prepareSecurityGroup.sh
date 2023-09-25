#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 FAMILYNAME" >&2
  exit 1
fi
FAMILY_NAME=$1

SECURITY_GROUP_NAME="security-group-for-network-for-${FAMILY_NAME}"
SECURITY_GROUP_DESCRIPTION="security group for the network of ${FAMILY_NAME}"

if aws ec2 describe-security-groups --group-name "${SECURITY_GROUP_NAME}" > /dev/null; then
  echo "  found security group"
  export SECURITY_GROUP_ID=`aws ec2 describe-security-groups --group-name "${SECURITY_GROUP_NAME}"  | jq -r '.SecurityGroups[0].GroupId' `
  echo "  id of security group is: " ${SECURITY_GROUP_ID}
else
  aws ec2 create-security-group \
    --group-name ${SECURITY_GROUP_NAME} \
    --description "${SECURITY_GROUP_DESCRIPTION}"
  export SECURITY_GROUP_ID=`aws ec2 describe-security-groups --group-name ${SECURITY_GROUP_NAME}  | jq -r '.SecurityGroups[0].GroupId' `
  echo "*** Security group obtained was: " ${SECURITY_GROUP_ID}
  echo "*** Authorizing for 22, 80, 443"
fi

aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port  22 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port  80 --cidr 0.0.0.0/0 > /dev/null
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null   



aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 0-65535 --cidr 0.0.0.0/0 > /dev/null   



