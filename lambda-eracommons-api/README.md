# REST API Organizations Web Service

This nodejs project implements a REST API web service to delive Organizational data through AWS API Gateway and Lambda function.

To build and deploy the project you have to have valid AWS credentials.  Execute the following commands:
```shell
npm install
npm run build
npm run deploy --arn=<ARN of IAM Role assigned to deployed Lambda Function>
```
The *samconfig.toml* file contains the configuration information for sam command:
* S3 bucket name to deploy the Cloud Formation stack
* Name of the Cloud Formation stack to create / update
* Region (*us-east-1*)
* Default confirmation flag
* Additional capabilities (*CAPABILITY_IAM* - creates an IAM role for Lambda function)

## REST API endpoints

The project uses NodeJS express framework to configure *routes* (API endpoints).  Currently the following endpoints are defined in [src/restapi.js](https://github.com/ypolonsky/nedorgs_webservice/blob/master/nedorg-lambda-restapi/src/restapi.js):

### /nedorgs/:sac

**Description:** Retrieve JSON record for the given SAC (**:sac**).

**Output:** 

```json
{
  "Item": {
    "sac": "SAC",
    "parent_sac": "Parent SAC",
    "inst": "Institute Name",
    "org_path": "Org Path",
    "ou_acr": "Organization Acronym",
    "ou_name": "Organization Name"
  }
}
```
### /nedorgs/:sac/children

**Description:** Retrieve JSON records for chidrent of the given SAC (**:sac**).

**Output:**

```json
{
  "Items": [
      {
        "sac": "SAC",
        "parent_sac": "Parent SAC",
        "inst": "Institute Name",
        "org_path": "Org Path",
        "ou_acr": "Organization Acronym",
        "ou_name": "Organization Name"
      }
    ]
}
```
### /nedorgs/:term/startwith

**Description:** Retrieve JSON records for records where SAC starts with given string (**:term**).

**Output:**

```json
{
  "Items": [
      {
        "sac": "SAC",
        "parent_sac": "Parent SAC",
        "inst": "Institute Name",
        "org_path": "Org Path",
        "ou_acr": "Organization Acronym",
        "ou_name": "Organization Name"
      }
    ]
}
```
## Project Architecture

The project represents the classic NodeJS express application. It can be run and debug locally:
```shell
npm run start
```
It invokes the app.local.js entry to configure express and listen on port 3000. Note, that it uses remote AWS DynamoDB table to retrieve organizational records. 

The project uses [**Serverless express** (*\@vendia/serverless-express*)](https://github.com/vendia/serverless-express) library as AWS Lambda function wrapper for NodeJS framework.

The project uses Serverless Application Model (sam) and it's CLI to build and deploy to AWS.  The configuration template [sam-template.yaml](sam-template.yaml) describes the following resources:

* **NedOrgsApi** - API Gateway configuration with deployment in *'prod'* tier
* **NedOrgsLambdaFunction** - Lambda function configuration of Lambda PROXY API Gateway type with relative path **/orgapi/v1/** and method **GET** only.  It defines IAM role to access and execute Lambda function as well as to access DynamoDB table.

The template configures the following outputs:

* **LambdaFunctionConsoleUrl** - Console URL for the Lambda Function
* **ApiGatewayApiConsoleUrl** - Console URL for the API Gateway API's Stage
* **ApiUrl** - Description: Invoke URL for your API. Clicking this link will perform a GET request
* **LambdaFunctionName** - Name of the Serverless Express Lambda Function
* **ApiHostName** - Host name with root folder to create URL for your API  
