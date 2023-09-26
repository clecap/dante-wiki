#!/bin/bash

# upload directory FAMILY_NAME/DIRECTORY-NAME to an elastic file system to be identified by $2

source ./global-names.sh

# Parse the command line
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 DIRECTORY-NAME  EFS-NAME" >&2
  exit 1
else 
  DIR=$1
  EFS_NAME=$2
fi


#region LOOK FOR EFS
echo
echo __________________________________
echo "*** Looking for the arn of the EFS with name: ${EFS_NAME}"
# on the special syntax below check https://vic.demuzere.be/articles/using-bash-variables-in-jq/
EFS_ARN=`aws efs describe-file-systems | jq  '.FileSystems' | jq -r --arg EFS_NAME "${EFS_NAME}" 'map(select(.Name==$EFS_NAME))' | jq -r '.[0].FileSystemArn'`
EFS_ID=`aws efs describe-file-systems | jq  '.FileSystems' | jq -r --arg EFS_NAME "${EFS_NAME}" 'map(select(.Name==$EFS_NAME))' | jq -r '.[0].FileSystemId'`
EFS_AZN=`aws efs describe-file-systems | jq  '.FileSystems' | jq -r --arg EFS_NAME "${EFS_NAME}" 'map(select(.Name==$EFS_NAME))' | jq -r '.[0].AvailabilityZoneName'`

echo

if [[ "$EFS_AZN" == "null" ]]; then
  echo "*** FATAL ERROR: Could not find filesystem ${EFS_NAME}"
  echo
  echo "*** TERMINATING ***"
  echo
  exit 1
else
  echo "*** Found id ${EFS_ID} and arn ${EFS_ARN} in availability zone ${EFS_AZN}"
fi
#endregion


echo __________________________________
BUCKET_NAME="s3-for-transfer-${EFS_NAME}"
echo "*** Preparing an S3 bucket to hold the files initially, name: ${BUCKET_NAME}"
aws s3api create-bucket --bucket ${BUCKET_NAME} --create-bucket-configuration LocationConstraint=${REGION_ID}
echo 

echo __________________________________
echo "*** Deleting content of S3 if any"
aws s3 rm s3://${BUCKET_NAME}  --recursive
echo

echo __________________________________
echo "*** Uploading files to S3 bucket"
aws s3 cp ${DIR} s3://${BUCKET_NAME} --recursive

echo
echo __________________________________
echo "*** ls of s3 bucket shows: "
aws s3 ls s3://${BUCKET_NAME}
echo

echo "*** Creating a bucket service role for transfer"
TRANSFER_SERVICE_ROLE_NAME="transfer-service-role-${BUCKET_NAME}"
TRANSFER_POLICY_NAME="transfer-policy-${BUCKET_NAME}"
aws iam create-role --role-name ${TRANSFER_SERVICE_ROLE_NAME} --assume-role-policy-document "{
  \"Version\": \"2012-10-17\",
  \"Statement\": [{\"Effect\": \"Allow\", \"Principal\": {\"Service\": \"datasync.amazonaws.com\"},\"Action\": \"sts:AssumeRole\"}]}
" 
echo "*** Attaching a policy to the service role of the transfer process"
aws iam put-role-policy --role-name ${TRANSFER_SERVICE_ROLE_NAME} --policy-name ${TRANSFER_POLICY_NAME} --policy-document "{
  \"Statement\": [
    {
      \"Action\": [
        \"sts:AssumeRole\",
        \"logs:CreateLogStream\", \"logs:CreateLogGroup\", \"logs:PutLogEvents\",
        \"ssm:GetParameters\",
        \"s3:*\"   
      ],
      \"Resource\": \"*\",
      \"Effect\": \"Allow\"
    }
  ],
  \"Version\": \"2012-10-17\"
}" > /dev/null
TRANSFER_SERVICE_ROLE=`aws iam get-role --role-name ${TRANSFER_SERVICE_ROLE_NAME} | jq -r '.Role.Arn'`
echo

BUCKET_ARN="arn:aws:s3:::${BUCKET_NAME}"

### DATASYNC source location is S3
echo __________________________________
echo "*** Creating a datasync source location, using S3 arn: ${BUCKET_ARN} and role ${TRANSFER_SERVICE_ROLE}"
SRC_ARN=`aws datasync create-location-s3 --s3-bucket-arn ${BUCKET_ARN}  --s3-config "{\"BucketAccessRoleArn\": \"${TRANSFER_SERVICE_ROLE}\"}" | jq -r '.LocationArn' `
echo "** Obtained source location with ARN ${SRC_ARN}"
echo


### SECURITY GROUP for efs access
echo __________________________________
echo "*** Creating a security group for accessing EFS during transfer..."
SECURITY_GROUP_NAME="upload-to-efs-${DIR}-${EFS_NAME}"
SECURITY_GROUP_DESCRIPTION="security group to upload to efs"
aws ec2 create-security-group \
    --group-name ${SECURITY_GROUP_NAME} \
    --description "${SECURITY_GROUP_DESCRIPTION}"
SECURITY_GROUP_ID=`aws ec2 describe-security-groups --group-name ${SECURITY_GROUP_NAME}  | jq -r '.SecurityGroups[0].GroupId' `
echo
echo "*** obtained group id: " ${SECURITY_GROUP_ID}
echo "*** Authorizing for 22, 80, 443"
aws ec2 authorize-security-group-ingress --group-id ${SECURITY_GROUP_ID} --protocol tcp --port 0-65535 --cidr 0.0.0.0/0 > /dev/null
echo 

### SUBNET
echo __________________________________
echo -n "*** Look for a subnet with availabilityZone equal to ${EFS_AZN}"
SUBNET=`aws ec2 describe-subnets --region ${REGION_ID} | jq -r --arg EFS_AZN "${EFS_AZN}" '.Subnets | map(select(.AvailabilityZone==$EFS_AZN)) | .[0].SubnetId' `
echo " found: ${SUBNET}"
echo

echo __________________________________
echo "*** Creating a mount target for EFS"
aws efs create-mount-target --file-system-id ${EFS_ID}  --subnet-id ${SUBNET} --security-groups ${SECURITY_GROUP_ID}
echo



echo __________________________________
echo "*** Creating the EFS as a datasync location for ${EFS_ARN}"
SUBNET_ARN="arn:aws:ec2:${REGION_ID}:${ACCOUNT_ID}:subnet/${SUBNET}"
echo "** SUBNET_ARN: ${SUBNET_ARN}"
SGGROUP_ARN="arn:aws:ec2:${REGION_ID}:${ACCOUNT_ID}:security-group/${SECURITY_GROUP_ID}"
echo "** SGGROUP_ARN: ${SGGROUP_ARN}"
DST_ARN=`aws datasync create-location-efs --efs-filesystem-arn ${EFS_ARN} --ec2-config "{ \"SubnetArn\": \"${SUBNET_ARN}\", \"SecurityGroupArns\": [\"${SGGROUP_ARN}\"] }" | jq -r '.LocationArn' `
echo "** Destination location ARN ${DST_ARN}"
echo


echo __________________________________
echo "*** Creating a data synchronization task src ${SRC_ARN} to ${DST_ARN}"
TASK_ARN=`aws datasync create-task --source-location-arn ${SRC_ARN}  --destination-location-arn ${DST_ARN} | jq -r '.TaskArn'`
echo "** Task ARN is ${TASK_ARN}"
echo

echo __________________________________
echo "*** Starting the data synchronization task"
aws datasync start-task-execution --task-arn ${TASK_ARN}



