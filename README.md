# Enterprise Data & Integration Services Web Services

The project contains the following modules:
* **aws-cf-scripts** - Set of cloud formation configuration templates to deploy and configure AWS resources
* **install-cloudguru** - Set of shell scripts to deploy and configure AWS resources with Cloud Formation stacks
* **load-nedorg-data** - nodejs application to load DynamoDB database with sample data from csv file
* **lambda-auth** - nodejs based Lambda authorizer function to authenticate and authorize the client that invokes API endpoints
* **lambda-userapi** - lightweight (*lambda-api* framework) nodejs based Lambda function to execute REST API endpoints
* **client-ang-nedorgs** - Angular application to deploy to EC2 Apache Web Server and to test Web Service

### Prerequisites

To build, debug, run, and deploy projects you need to install the following:

* **npm** - Node JavaScript package manager (https://docs.npmjs.com/cli/v6/configuring-npm/install)
* **aws cli** - AWS Command Line Interface (https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
* **sam cli** - SAM (Serverless Application Model) Command Line Interface (https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) 
* **AWS Credentials** - AWS Access Key and AWS Secret Access Key for previsioned account

The AWS credentials can be installed by using aws cli command (*access ID and Key values are fake*):
```
aws configure
AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
Default region name [None]: us-east-1
Default output format [None]: json
```

See https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html for further configuration details.  For example, you can specified a profile name if you have credentials for multiple AWS accounts.

### NOTE
**Keep in mind that all shell scripts are for macOS and Linux OS.  The alternative batch files can be created for Windows**

### Step By Step instructions to configure, build, deploy, and run the service in *acoudguru.com* playground instance

1. Ensure that all prerequisites actions are completed
2. In **install-cloudguru** project run *exec-aws.sh* script to create necessary AWS resources
```
./exec-aws.sh
```
3. In **install-cloudguru** project run *load-data.sh* script to populate Dynamo DB table with sample ned org data
```
./load-data.sh
```
4. In **install-cloudguru** project run *sa-deploy.sh* script to create API Gateway and Lambda functions resources:
```
./sam-deploy.sh
```
5. In **lambda-auth** project build the zip package for Lambda Authorizer
```
./npm run zip
```
6. Open *lambda-auth-dev* Lambda function in AWS console and upload the created zip file
7. In **lambda-userapi** project build the zip package for Lambda Rest API
```
./npm run zip
```
8. Open *lambda-userapi-dev* Lambda function in AWS console and upload the created zip file
9. get the URL of api from API Gateway Resources (in dev tier) and run **curl** command:
```
curl -i https://user:password@<API Gateway URL>/v1/nedorgs/HNC14
```
10. Check the results of the command.
11. Open AWS Console Cloud Watch and check the logs produces by both Lambda functions 
