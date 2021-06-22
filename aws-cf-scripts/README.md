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

