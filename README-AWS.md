
# Description #

This is a **boiler plate project** to automate **launching docker** images and volumes 
* locally in docker for development purposes 
* remotely to Amazon cloud aws using a **git commit**.

## Goals ##
* Provide a **set of shell scripts** for automatizing the workflow. 
* Document my learning process in AWS in concepts instead of screenshots of AWS console.

## It does ##
* Setting up a container registry using **ECR Elastic Container Registry**
* Setting up an input source area using **S3**
* Building the docker image using **CodeBuild**
* Informing the user by email on the build process using **SNS** and **CloudWatch**
* Deploying the docker image to Amazon Fargate using **ECS Elastic Container Service**
* Determining the public IP addresses bound to the tasks
* Connecting these IP addresses to a predetermined domain using **Route53**
* Managing the security groups required for the network access
* Setting up the roles providing the necessary permissions using **ECS IAM**
* Setting up an **EFS Elastic Filesystem**
* Uploading files to an **EFS Elastic FIlesystem**
* Allow ssh entry to the server for manual checks and maintenance.
* Provides **https** settings
* Does a **http to https redirect**
* **http2** support


## It does not (yet) ##
* Allow public key ssh entry
* Allow yubikey as 2fa for ssh entry into the server
* Connecting the scripts to a github push event
* Connecting the service to a Route53 managed domain
* Running some elementary service tests
* Backup the elastic file system
* Encryption at rest
* Encryption in transport - enforce that Mysql is accepting only encrypted connections and that webserver uses them as well. https://dev.mysql.com/doc/refman/5.7/en/using-encrypted-connections.html
* Startup only on demand, see https://aws.plainenglish.io/how-on-demand-provisioning-your-ecs-serverless-apps-can-save-you-money-fdfaee3ef2f
* Proper handling of container secrets as described in https://stackoverflow.com/questions/71704931/set-aws-secret-manager-value-in-docker-environment
** Maybe easier and better not to depend on aws too much - before we go into production with a container we ssh into the container and make the changes manually ------ but this is not so efficient ?!?!? - ?!?!?!ß
* Take care of all mediawiki security issues mentioned in https://www.mediawiki.org/wiki/Manual:Security
* Implement mysql dumps
* Implement mysql dumps properly as in https://serverfault.com/questions/231300/mysqldump-with-single-transaction-option-on-live-production-servers?rq=1

A more detailed description can be found in the
[Wiki](https://github.com/clecap/continuous-deployment-test/wiki).

## Lessons Learned ##
* If things do not work it usually is due to a forgotten configuration parameter. 
* You often forget cleaning up resources somewhere and continue to pay for them. 
* You often forget specific requirements of tasks, some of which are taken care of by the web interface of aws automagically without making them explicit. The CLI / shell script approach requires them to be coded explicitely into the shell.
* AWS CLI commands have an inconsistent API (such as requiring ARNs, ids, names or creation tokens). This approach can smoothen out this problem.

### Structure: Closed loop versus status ###



