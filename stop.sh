#!/bin/bash

source ./global-names.sh
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 FAMILYNAME" >&2
  exit 1
fi
FAMILY_NAME=$1

CLUSTER_NAME="cluster-${FAMILY_NAME}"
SECURITY_GROUP_NAME="security-group-for-network-for-${FAMILY_NAME}"
TASK_DEFINITION_NAME="task-${FAMILY_NAME}"
SERVICE_NAME="Service-running-${TASK_DEFINITION_NAME}"
REPOSITORY_NAME="reposi-${FAMILY_NAME}"
PROJECT_NAME="project-${FAMILY_NAME}"


echo "*** Stop all running tasks of cluster ${CLUSTER_NAME}"
TASK_ARNS=`aws ecs list-tasks --cluster ${CLUSTER_NAME} | jq -r '.taskArns | join(" ")'` 

echo "  Iterating over all tasks ${TASKS_ARNS} " 
echo 
for TASK_ARN in $TASK_ARNS
do 
  echo "  Stopping task with arn: " $TASK_ARN
  aws ecs stop-task --cluster ${CLUSTER_NAME} --task ${TASK_ARN} > /dev/null
done  

echo "*** Deleting all services ${SERVICE_NAME} in cluster ${CLUSTER_NAME}"
aws ecs delete-service --cluster ${CLUSTER_NAME} --service ${SERVICE_NAME} --force > /dev/null

echo "*** Deleting security group: ${SECURITY_GROUP_NAME}"
aws ec2 delete-security-group --group-name ${SECURITY_GROUP_NAME} > /dev/null

echo "*** Deleting cluster: ${CLUSTER_NAME}"
aws ecs delete-cluster --cluster ${CLUSTER_NAME} > /dev/null
