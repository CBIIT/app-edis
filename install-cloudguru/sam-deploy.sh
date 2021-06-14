#!/bin/bash

usage() { echo "Usage: $0 [-a <account>] [-t <tier>] [-p profile] [-h]" 1>&2; exit 1; }

account="107424568411"
tier="dev"
cf_dir="../aws-cf-scripts"
profile="default"

while getopts ha:t:p: opt
do
    case "${opt}" in
        h) usage
          ;;
        a) account=${OPTARG}
          ;;
        t) tier=${OPTARG}
          ;;
        p) profile=${OPTARG}
          ;;
        *) usage
          ;;
    esac
done

s3bucket="cf-templates-$account-us-east-1"
lambda_auth_code="lambda-auth.zip"
lambda_userapi_code="lambda-userapi.zip"

sam_template="sam-openapi-template.yaml"

aws s3 cp --profile ${profile} "../lambda-auth/$lambda_auth_code" "s3://$s3bucket"
aws s3 cp --profile ${profile}  "../lambda-userapi/$lambda_userapi_code" "s3://$s3bucket"

sname="app-serverless"
s3_prefix="userapi-serverless"
region="us-east-1"
capabilities="CAPABILITY_IAM"

lambda_role_arn=$(aws cloudformation describe-stacks  --profile ${profile} --stack-name ${tier}-userapi-iam-lambda --query "Stacks[0].Outputs[?OutputKey=='LambdaOrgapiRoleArn'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')

echo -e "Parameters: $tier $lambda_role_arn"

sam deploy -t $cf_dir/$sam_template  --profile ${profile} --stack-name ${tier}-userapi-app-serverless --s3-bucket $s3bucket --s3-prefix $s3prefix --region $region --no-confirm-changeset --capabilities $capabilities --parameter-overrides \
                    ParameterKey=Environment,ParameterValue=$tier \
                    ParameterKey=LambdaRoleArn,ParameterValue=$lambda_role_arn \
                    ParameterKey=S3bucket,ParameterValue=$s3bucket \
                    ParameterKey=Issuer,ParameterValue=https://iam-lab2.cancer.gov/oauth2/auss3iezeLBILuhGa1d6 \
                    ParameterKey=Audience,ParameterValue=api://default

echo -e "\nServerless Cloud Formation Stack has been deployed"

