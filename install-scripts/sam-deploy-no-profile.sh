#!/bin/bash

usage() { echo "Usage: $0 [-a <s3bucket>] [-t <tier>] [-h]" 1>&2; exit 1; }

s3bucket="cf-templates-107424568411-us-east-1"
tier="dev"
cf_dir="../aws-cf-scripts"

while getopts ha:t:p: opt
do
    case "${opt}" in
        h) usage
          ;;
        a) s3bucket=${OPTARG}
          ;;
        t) tier=${OPTARG}
          ;;
        *) usage
          ;;
    esac
done

sam_template="sam-openapi-template.yaml"

s3prefix="app-edis-${tier}"
region="us-east-1"
capabilities="CAPABILITY_IAM"

lambda_role_arn=$(aws cloudformation describe-stacks  --stack-name ${tier}-edis-eracommons-iam-lambda-role --query "Stacks[0].Outputs[?OutputKey=='LambdaOrgapiRoleArn'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')
dynamodb_role_arn=$(aws cloudformation describe-stacks  --stack-name ${tier}-userapi-iam-apigtwy-role --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayAccessDdbRoleArn'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')
#lambda_role_arn=$(aws cloudformation describe-stacks  --stack-name iam-lambda-roles --query "Stacks[0].Outputs[?OutputKey=='LambdaOrgapiRoleArn'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')
#dynamodb_role_arn=$(aws cloudformation describe-stacks  --stack-name iam-apigateway-roles --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayAccessDdbRoleArn'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')

echo -e "Parameters: $tier $lambda_role_arn"

sam deploy -t $cf_dir/$sam_template --stack-name ${tier}-edis-app-serverless --s3-bucket $s3bucket --s3-prefix $s3prefix \
                                    --region $region --no-confirm-changeset --capabilities $capabilities \
                                    --parameter-overrides \
                    Environment=$tier \
                    LambdaRoleArn=$lambda_role_arn \
                    DynamoDbRoleArn=$dynamodb_role_arn \
                    S3bucket=$s3bucket \
                    UsersTableName=extusers-$tier \
                    Issuer=https://iam-stage.cancer.gov/oauth2/aus114k6x72d19Eum0h8 \
                    Audience=api://default

echo -e "\nServerless Cloud Formation Stack has been deployed"
