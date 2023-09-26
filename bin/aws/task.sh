#!/bin/bash

source ./global-names.sh

# Parse the command line
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 FAMILYNAME  IMAGE_VERSION" >&2
  exit 1
fi
if [ "$#" -eq 1 ]; then
  FAMILY_NAME=$1
  IMAGE_TAG="current"
fi
if [ "$#" -eq 2 ]; then
  FAMILY_NAME=$1
  IMAGE_TAG=$2
fi
if [ "$#" -gt 2 ]; then
  echo "Usage: $0 FAMILYNAME  IMAGE_VERSION" >&2
  exit 1
fi

CONTAINER_NAME="container-${FAMILY_NAME}"

echo
echo __________________________________
source getRepositoryName.sh ${FAMILY_NAME}
IMAGE_NAME="${REPOSITORY_URI}:${IMAGE_TAG}"
echo


#region CREATING TASK EXECUTION ROLE
echo __________________________________
echo "*** Creating a role for executing the task..."
TASK_EXECUTION_ROLE_NAME="role-for-executing-task-${FAMILY_NAME}"
aws iam create-role --role-name ${TASK_EXECUTION_ROLE_NAME} --assume-role-policy-document "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [{\"Effect\": \"Allow\", \"Principal\": {\"Service\": \"ecs-tasks.amazonaws.com\"},\"Action\": \"sts:AssumeRole\"}]}
" 
TASK_EXECUTION_ROLE=`aws iam get-role --role-name ${TASK_EXECUTION_ROLE_NAME} | jq -r '.Role.Arn'`

TASK_EXECUTION_POLICY_NAME="task-execution-policy-for-${FAMILY_NAME}"
### Attach a policy according to https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html
# NOTE: we here allow access to all resources, we could make this more tight 
echo "*** Adding policy to the role for executing the task..."
echo "   -------------- Policy name: ${TASK_EXECUTION_POLICY_NAME}"
aws iam put-role-policy --role-name ${TASK_EXECUTION_ROLE_NAME} --policy-name ${TASK_EXECUTION_POLICY_NAME} --policy-document "{
  \"Statement\": [
    {
      \"Action\": [
        \"ecr:GetAuthorizationToken\",  \"ecr:BatchCheckLayerAvailability\",
        \"ecr:GetDownloadUrlForLayer\", \"ecr:BatchGetImage\",
        \"logs:CreateLogStream\", \"logs:CreateLogGroup\", \"logs:PutLogEvents\",
        \"elasticfilesystem:*\"
      ],
      \"Resource\": \"*\",
      \"Effect\": \"Allow\"
    }
  ],
  \"Version\": \"2012-10-17\"
}"

echo "*** Adding AWS managed policy AmazonElasticFileSystemFullAccess"
aws iam attach-role-policy --role-name ${TASK_EXECUTION_ROLE_NAME} --policy-arn arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess
 #endregion


#region LOCAL TASK SPECIFICATIONS
echo __________________________________
echo "*** Getting local task specifications"
echo "    Portmappings"
PORT_MAPPINGS=`cat ${FAMILY_NAME}/def/portmappings.json5 | json5conv`
echo "      ${PORT_MAPPINGS}"
echo

echo "    Volumes"
VOLUMES=`cat ${FAMILY_NAME}/def/volumes.json5 | json5conv`
echo "      ${VOLUMES}"
echo

echo "    Mountpoints"
MOUNT_POINTS=`cat ${FAMILY_NAME}/def/mountpoints.json5 | json5conv`
echo "    ${MOUNT_POINTS}"
echo
#endregion


echo __________________________________
echo "*** Registering task definition"
aws ecs register-task-definition  \
  --family        ${FAMILY_NAME}  \
  --network-mode  "awsvpc"  \
  --container-definitions "[{
    \"name\":           \"${CONTAINER_NAME}\", 
    \"image\":          \"${IMAGE_NAME}\",
    \"portMappings\":   ${PORT_MAPPINGS},
    \"logConfiguration\": {
      \"logDriver\": \"awslogs\",
      \"options\": {
        \"awslogs-group\": \"${FAMILY_NAME}-logs-group\",
        \"awslogs-region\": \"${REGION_ID}\",
        \"awslogs-create-group\": \"true\",
        \"awslogs-stream-prefix\": \"${FAMILY_NAME}\"
      }
    },         
    \"essential\":     true, 
    \"entryPoint\":    [\"/entrypoint.sh\"], 
    \"command\":       [\"/entrypoint.sh\"],
    \"mountPoints\":   ${MOUNT_POINTS}
    }]"  \
  --requires-compatibilities FARGATE \
  --volumes "${VOLUMES}"  \
  --execution-role-arn ${TASK_EXECUTION_ROLE} \
  --cpu    256 \
  --memory 512 | jq -r '.taskDefinition.taskDefinitionArn'

echo "*** Registration of task definition completed" 


   



