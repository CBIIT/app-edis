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

sam_template="sam-sumologic-pipeline.yml"

s3prefix="app-edis-${tier}"
region="us-east-1"
capabilities="CAPABILITY_IAM"

lambda_role_arn=$(aws cloudformation describe-stacks  --stack-name iam-sumologic-role-template --query "Stacks[0].Outputs[?OutputKey=='SumoCWLambdaExecutionRoleArn'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')
log_group=$(aws cloudformation describe-stacks  --stack-name ${tier}-edis-app-serverless --query "Stacks[0].Outputs[?OutputKey=='ApiAccessLogGroup'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')

echo -e "Parameters: $tier $lambda_role_arn"

sam deploy -t $cf_dir/$sam_template --stack-name ${tier}-edis-sumologic --s3-bucket $s3bucket --s3-prefix $s3prefix \
                                    --region $region --no-confirm-changeset --capabilities $capabilities \
                                    --parameter-overrides \
                    NCIEnvironment=$tier \
                    EmailID=yakov.polonsky@nih.gov \
                    SumoCWLogGroup=$log_group \
                    SumoCWLambdaExecutionRoleArn=$lambda_role_arn

echo -e "\nServerless Cloud Formation Stack has been deployed"
