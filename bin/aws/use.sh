#!/bin/bash

source ./global-names.sh
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 FAMILYNAME" >&2
  exit 1
fi
FAMILY_NAME=$1

CLUSTER_NAME="cluster-${FAMILY_NAME}"
TASK_ARNS=`aws ecs list-tasks --cluster ${CLUSTER_NAME} | jq -r '.taskArns | join(" ")'` 

# count number of tasks; xargs does the trimming of the result
NUM_TASKS=`echo TASK_ARNS | wc -w | xargs`

echo __________________________________
echo "*** Number of tasks found: ${NUM_TASKS}: ${TASK_ARNS}"

if [ ${NUM_TASKS} -eq 1 ]; 
then
  echo "*** Connecting public IP address to hostname ${FAMILY_NAME}.${BASE_DOMAIN}"
  TASK_ARN=$TASK_ARNS
  echo "    Found task:" $TASK_ARN
  NETWORK_INTERFACE_ID=`\
  aws ecs describe-tasks --task ${TASK_ARN} --cluster ${CLUSTER_NAME} | jq '.tasks[0].attachments[0].details' | jq -r 'from_entries.networkInterfaceId'`
  echo "    Found network interface: ${NETWORK_INTERFACE_ID}"
  PUBLIC_IP=`aws ec2 describe-network-interfaces --network-interface-ids ${NETWORK_INTERFACE_ID} | jq -r '.NetworkInterfaces[0].Association.PublicIp' `
  echo "    Found public ip: ${PUBLIC_IP}"
  HOST_ADDR="${FAMILY_NAME}.${BASE_DOMAIN}"
  aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch "{
    \"Comment\": \"Update record to reflect new IP address for a system by continuous integration mechanism for ${FAMILY_NAME}\",
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {\"Name\": \"${HOST_ADDR}\", \"Type\": \"A\", \"TTL\": 10, \"ResourceRecords\": [{\"Value\": \"${PUBLIC_IP}\"} ] } } ] } " > /dev/null
  echo "    Revoking local ssh key, to make things easier"
  ssh-keygen -R ${HOST_ADDR}
  echo
  echo "*** DONE: Connected to: ${HOST_ADDR}"
else
echo "*** Found more than one task, must iterate over all tasks"
echo
NUMBER=0 
for TASK_ARN in $TASK_ARNS
do 
  echo "    For number ${NUMBER} I got " $TASK_ARN
  NETWORK_INTERFACE_ID=`\
  aws ecs describe-tasks --task ${TASK_ARN} --cluster ${CLUSTER_NAME} | jq '.tasks[0].attachments[${NUMBER}].details' | jq -r 'from_entries.networkInterfaceId'`
  echo "    For number ${NUMBER} I got network interface: ${NETWORK_INTERFACE_ID}"
  PUBLIC_IP=`aws ec2 describe-network-interfaces --network-interface-ids ${NETWORK_INTERFACE_ID} | jq -r '.NetworkInterfaces[${NUMBER}].Association.PublicIp' `
  echo "    For number ${NUMBER} I got public ip: ${PUBLIC_IP} "
  printf '  %-15s' ${PUBLIC_IP}
  printf '%-6s%-20s%-10s%-20s\n' " for " ${NETWORK_INTERFACE_ID} " at task " ${TASK_ARN}

  HOST_ADDR="${FAMILY_NAME}-${NUMBER}.${BASE_DOMAIN}"
  aws route53 change-resource-record-sets --hosted-zone-id ${HOSTED_ZONE_ID} --change-batch "{
    \"Comment\": \"Update record to reflect new IP address for a system by continuous integration mechanism for ${FAMILY_NAME}\",
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {\"Name\": \"${HOST_ADDR}\", \"Type\": \"A\", \"TTL\": 10, \"ResourceRecords\": [{\"Value\": \"${PUBLIC_IP}\"} ] } } ] } " > /dev/null
  echo "    Revoking local ssh key, to make things easier"
  ssh-keygen -R ${HOST_ADDR}
  echo 
  echo "*   Connected to: ${HOST_ADDR}"
  NUMBER=$(($NUMBER + 1))
done 
fi



 

