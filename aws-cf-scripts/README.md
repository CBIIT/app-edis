## Description of AWS Cloud Formation templates for deploying API Gateway PoC AWS components 

The AWS Cloud Formation templates are depicted below:

The **input parameters** for templates are following:

- **Environment** (dev, test, qa, stage, prod)


![cf_diagram](../docs/images/iam-lambda-role-template.png)
![cf_diagram](../docs/images/iam-apigtw-role-template.png)
![cf_diagram](../docs/images/ddb-serverless-template.png)

The **input parameters** for Serverless ApplicationModel (SAM) template are following:

- **Environment** (dev, test, qa, stage, prod)
- **LambdaRoleArn** – ARN of Lambda function that executed methods of API
- **DynamoDbRoleArn** – ARN of role to permit API method to access DynamoDB table
- **S3Bucket** – S3 bucket name that contains Lambda functions executable code
- **Issuer** – Okta Authentication Server URL
- **Audience** – Okta Authentication audience (api://default)
- **UsersTableName** – DynamoDB NIH external users table name

![cf_diagram](../docs/images/sam-openapi-template.png)

## Installation

### Step by step instruction to deploy and configure service

#### Prerequisites

To build, debug, run, and deploy projects you need to install the following:

* **npm** and **Node.js** - Node JavaScript package manager (https://docs.npmjs.com/cli/v6/configuring-npm/install)
* **zip** - A file compression and packaging utility compatible with PKZIP (For CentOS - https://centos.pkgs.org/7/centos-x86_64/zip-3.0-11.el7.x86_64.rpm.html)
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

### Step by step manual instructions

1. Verify that all necessary appications are installed and available (see _Prerequisites_)
2. Setup eRA Commond database credentials:
   1. Open AWS Console and goto __Secrets Manager__
   2. Create a new secret __era-commons-connect-{tier}__
```
user: <EDIS CBIIT{tier} service account name>
pwd: <password>
connect: <CBIITSG{tier} Connection String>
```
3. Switch to **install-scripts** folder
4. Run the *exec-aws-no-profile.sh* script.  This script deploys CloudFormation templates to setup DynamoDB table for the given tier
The script creates CloudFormation stack if they don't exist or creates change set and deploys only the changed portions of templates.
Pass -a {S3 bucket name} to store CloudFormation templates and -t {tier} to deploy to selected tier

```shell
./exec-aws-no-profile.sh [-a <s3bucket>] [-t <tier>] [-p profile] [-h]
```
The following template is created / updated by running this script:
- *ddb-serverless-template.yaml* - Creates / updates dynamodb table **'extusers'**

********
4. Run the *sam-deploy.sh* script. It runs *sam deploy* command to deploy the *sam-openapi-template.yaml* template.  The generated template creates / updates CloudFormation stack which in turn creates / updates API Gateway interface, Lambda Authorizer, and Lambda Execution function.

```shell
./sam-deploy.sh [-a <s3bucket>] [-t <tier>] [-p profile] [-h]
```

The scripts gets the existing IAM roles for API Gateway and Lambda function and passes them into sam deply command along with tier, S3 Bucket name, and Okta authentication server credentials

5. Optionally, the *load-data.sh scripts populates Dynamo DB table with fake data stored in *docs/NIH External Accounts - No Roles - Address.json* file

Note, that Lambda Authorization and Lambda execution functions code are prebuilt and pushed to github as zip files into corresponding folders.
Alternatively, you can build these files with the command *npm run zip* in **lambda-auth** and **lambda-userapi** folders.

### CI/CD Jenkins deployment

The automated deployment is setup in dev instance of Jenkins.  It hides the AWS access keys in Jenkins credentials files.
The deployment job (https://i2e-jenkins-dev.nci.nih.gov/jenkins/job/_default/job/_lower/job/_sandbox/job/_aws_pocs/job/AWS_edis/) has the following input parameters:

- GIT_TAG - branch or tag the app-edis GitHub project (https://github.com/CBIIT/app-edis)
- AWS_ACCESS - AWS credentials - by selecting different AWS credentials you can deploy the application into different AWS accounts
- S3_BUCKET_CF - S3 Bucket for CloudFormation templates and source code. Will be created if it does not exist
- TIER - Dropdown selection of API Gateway deployment stage name (dev, qa, test, stage, prod)

The AWS Credentials can be setup by opening the Jenkins Credentials Credentioals view (https://i2e-jenkins-dev.nci.nih.gov/jenkins/job/_default/job/_lower/credentials/) and adding a new Credentials or updating the existing one if needed.
Store *AWS Acccess Key ID* as *Username* and *AWS Secret Access Key* as *Password*:

![jenkins](../docs/images/jenkins-credentials.png)

You can make changes in cloud formation template and Lambda functions source code, push it into GitHub repository and run the Jenkins job multiple times.
CloudFormation deployments will determine the changes, create corresponding change sets and deploy them into AWS account.

See [change-management.docx](doc/change-management.docx) document for details of Cloud Formation change management

