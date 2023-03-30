# Enterprise Data & Integration Services Web Services

[![CI](https://github.com/CBIIT/app-edis/actions/workflows/lambda-build.yml/badge.svg)](https://github.com/CBIIT/app-edis/actions/workflows/lambda-build.yml)

The project contains the following modules:
* **aws-cf-scripts** - Set of cloud formation configuration templates to deploy and configure AWS resources
* **install-scripts** - Set of shell scripts to deploy and configure AWS resources with Cloud Formation stacks
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
  
    OR
* **AWS OIDC Provider** - AWS OpenID Connect identity provider

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

## Step By Step instructions to configure, build, and deploy the service in NCI CBIIT AWS instance

1. Build **lambda-auth** Lambda function
```shell
cd lambda-auth
npm run zip
cp lambda-auth.zip ../lambda-zip/.
cd ..
```
2. Build **lambda-userapi** Lambda function
```shell
cd lambda-userapi
npm run zip
cp lambda-userapi.zip ../lambda-zip/.
cd ..
```
3. Build **lambda-eracommons** Lambda function
```shell
cd lambda-eracommons
#create oracledb layer distribution
npm install
npm run layer

#create lambda zip distribution
npm run zip
cp lambda-eracommons.zip ../lambda-zip/.
cd ..
```
4. ***For Cloud Team*** - Create S3 bucket for CloudFormation templates if it does not exist
```shell
aws s3api create-bucket --profile <profile> --bucket "<S3 Bucket Name>" --region us-east-1
# or without profile
aws s3api create-bucket --bucket "<S3 Bucket Name>" --region us-east-1
```
5. Create DynamoDB table to store user information
```shell
cd install-scripts
./exec-aws-no-profile.sh -a <S3 Bucket Name> -t <tier>
cd ..
```
6. Load DynamoDB table with initial data from json file. See  the example of the file in docs folder - [NIH External Accounts - No Roles - Address.json](/docs/NIH%20External%20Accounts%20-%20No%20Roles%20-%20Address.json).
The easiest way to create this file is to extract csv file from the database and convert it to json using online converter.
```shell
cd install-scripts
./load-data.sh -t <tier> -f <filename> [-p <aws profile>]
cd ..
```
7. ***For Cloud Team*** - Create roles for *lambda-eracommons* Lambda function and for API Gateway
```shell
cd install-scripts
./create-roles-no-profile.sh -a <S3 Bucket Name> -t <tier>
cd ..
```
8. Deploy API gateway and Lambda functions for authorization and user api
```shell
cd install-scripts
./sam-deploy-no-profile.sh -a <S3 Bucket Name> -t <tier>
cd ..
```
9. Deploy lambda-eracommons Lambda function. First edit the *install-scripts/sam-deploy-lambda-eracommons-no-profile.sh* file
and set the VPC subnet1, subnet2, and security group sgid (lines 23-25) with values from the AWS account
```shell
cd install-scripts
./sam-deploy-lambda-eracommons-no-profile.sh -a <S3 Bucket Name> -t <tier>
cd ..
```
10. Set the scheduler event to run lambda-eracommons Lambda function once a day to refresh the DynamoDB table from eRA Commons database


