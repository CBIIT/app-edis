#!/bin/bash

usage() { echo "Usage: $0 [-a <s3bucket>] [-t <tier>] [-p profile] [-c] [-h]" 1>&2; exit 1; }

s3bucket="cf-templates-107424568411-us-east-1"
tier="dev"
profile=""
cf_dir="../aws-cf-scripts"
s3bucket_create=0


while getopts hca:t:p: opt
do
    case "${opt}" in
        h) usage
          ;;
        a) s3bucket=${OPTARG}
          ;;
        t) tier=${OPTARG}
          ;;
        p) profile=${OPTARG}
          ;;
        c) s3bucket_create=1
          ;;
        *) usage
          ;;
    esac
done


cf_ddb="ddb-serverless-template.yaml"
cf_iam_lambda="iam-lambda-role-template.yaml"
cf_iam_apigateway="iam-apigtw-role-template.yaml"

echo -e "Create ${s3bucket} if it does not exist"

s3exist=$(aws s3api head-bucket --bucket $s3bucket --profile ${profile} 2>&1 || true)
if [ -n "${s3exist}" ] 
 then
    echo -e "Bucket ${s3bucket} does not exist. Creating a new one"
    aws s3api create-bucket --profile ${profile} --bucket "$s3bucket" --region us-east-1
fi

aws cloudformation deploy --profile ${profile} --stack-name ${tier}-userapi-iam-lambda --template-file "$cf_dir/$cf_iam_lambda" --s3-bucket ${s3bucket} --parameter-overrides \
        Environment=${tier} --capabilities CAPABILITY_NAMED_IAM
aws cloudformation deploy --profile ${profile} --stack-name ${tier}-userapi-iam-apigtwy --template-file "$cf_dir/$cf_iam_apigateway" --s3-bucket ${s3bucket} --parameter-overrides \
        Environment=${tier} --capabilities CAPABILITY_NAMED_IAM
aws cloudformation deploy --profile ${profile} --stack-name ${tier}-userapi-ddb  --template-file "$cf_dir/$cf_ddb" --s3-bucket ${s3bucket} --parameter-overrides \
        Environment=${tier}

stackStatus=null
echo -n "Creating stacks..."
while [ "$stackStatus" != 'CREATE_COMPLETE' ] && [ "$stackStatus" != 'ROLLBACK_COMPLETE' ] && [ "$stackStatus" != 'CREATE_FAILED' ] && [ "$stackStatus" != 'UPDATE_COMPLETE' ] && [ "$stackStatus" != 'UPDATE_FAILED' ]; do
    sleep 2s
    echo -n "."
    stackStatus=$(aws cloudformation describe-stacks --stack-name ${tier}-userapi-ddb --profile $profile --query "Stacks[0].StackStatus" | sed -e 's/^"//' -e 's/"$//')
done

if [ "$stackStatus" = 'CREATE_COMPLETE' ]
then
  echo -e "\nCloudFormation stacks have been created successfully."
elif [ "$stackStatus" = 'UPDATE_COMPLETE' ]
then
  echo -e "\nCloudFormation stacks have been updated successfully."
else
  echo -e "\nFAILED: Failed to create or update CloudFormation stacks.  Please, check the CloudFormation stacks in AWS Console."
  exit 1
fi
