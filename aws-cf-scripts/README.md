# Description of AWS Cloud Formation templates for deploying EDIS AWS components 

The AWS Cloud Formation templates are depicted below:

## iam-lambda-role-template.yaml
**Description:** Creates IAM role for lambda-userapi Lambda function

**Input Parameters:**
- **Environment** - the tier (dev, test, qa, stage, prod)

**Resources**

| lambda-userapi-api-{environment}-role | IAM Role |   
| --- | --- |
The role allows to get events from API Gateway, read/write DynamoDB table, log messages to CloudWatch and to XRay
<br>The role includes the following AWS managed policies:
- arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
- arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole
- arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
- arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess

## iam-apigtw-role-template.yaml
**Description:** Creates IAM role for API Gateway

**Input Parameters:**
- **Environment** - the tier (dev, test, qa, stage, prod)
- **DdbTableArn** - ARN of DynamoDB userinfo table

**Resources**

| apigateway-userapi-ddb-{environment}-role | IAM Role |   
| --- | --- |
The role allows API Gateway methods to access DynamoDB table directly, without lambda-userapi Lambda function
<br>The role includes the following AWS managed policies:
- arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs

It also defines inline policy to access the given DynamoDB table defined by *DdbTableArn*:
```yaml
        - PolicyName: !Sub ddbExtusersRead-${Environment}
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Sid: ddbPermissions
                Effect: Allow
                Action:
                  - dynamodb:*
                Resource:
                  - !Ref DdbTableArn
                  - !Sub ${DdbTableArn}/index/*

```
##ddb-serverless-template.yaml
**Description:** Creates DynamoDB table to store eRA Commons external User Records

**Input Parameters:**
- **Environment** - the tier (dev, test, qa, stage, prod)

**Resources**

| extusers-{environment} | DynamoDB table |   
| --- | --- |
The table has **Primary Key** USER_ID
<br>Global Secondary Index (GSI) **dateIndex** - Hash Key is LAST_UPDATED_DAY and Sort Key is USER_ID
<br>Global Secondary Index (GSI) **logingovIndex** - Hash Key is LOGINGOV_USER_ID and Sort Key is USER_ID

## sam-openapi-template.yaml
**Description:** Creates API Gateway based on open API swagger file and deploys lambda-auth and lambda-userapi Lambda funcitons 

**Input Parameters:**

- **Environment** (dev, test, qa, stage, prod)
- **LambdaRoleArn** – ARN of Lambda function that executed methods of API
- **DynamoDbRoleArn** – ARN of role to permit API method to access DynamoDB table
- **S3Bucket** – S3 bucket name that contains Lambda functions executable code
- **Issuer** – Okta Authentication Server URL
- **Audience** – Okta Authentication audience (api://default)
- **UsersTableName** – DynamoDB NIH external users table name

**Resources**

| eRA Commons User API | API Gateway |   
| --- | --- |

API Gateway deployment is based on [swagger-userapi-v3.yaml](/swagger-userapi-v3.yaml) open API specification template.
<br>The API Gateway has the following properties:
- stage name ( {environment} )
- type REGIONAL
- Authorization by lambda-auth Lambda Authorization function
- Authorization by Resource Policy limmiting access by IP ranges
- Enabled CloudWatch logging (access and execution log groups)
- Enabled XRay tracing

| lambda-auth-{env} | Lambda Function |   
| --- | --- |

The Lambda function Authorizer decodes the "_Authorization_" request header, verifies the OAuth 2 token with Okta
authorization server

| lambda-userapi-{Environment} | Lambda Function |   
| --- | --- |

The Lambda function implements V1 API Gateway endpoints - it retrieves user by ID, by Date, by Date Range, and by Login.gov ID

| CBIIT-SN-apiGatewayPoC1-${Environment} | API Key |   
| --- | --- |

API Key for ServiceNow client associated with selected API Usage Plan. The purpose is Usage Monitoring

| CBIIT-SN-apiGatewayPoC1-usage-plan-${Environment} | API Usage Plan |   
| --- | --- |

API Usage Plan for ServiceNow client. The purpose is Usage Monitoring

## CI/CD Jenkins deployment

The automated deployment has been setup in dev instance of Jenkins.  It hides the AWS access keys in Jenkins credentials files.
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

## Github Actions Deployment

See github Action [https://github.com/CBIIT/app-edis/actions](https://github.com/CBIIT/app-edis/actions) for implementation POC.
