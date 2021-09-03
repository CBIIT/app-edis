#!/bin/bash

usage() { echo "Usage: $0 [-a <s3bucket>] [-t <tier>] [-h]" 1>&2; exit 1; }

s3bucket="cf-templates-107424568411-us-east-1"
tier="dev"
cf_dir="../aws-cf-scripts"

while getopts ha:t: opt
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

cf_iam_lambda="iam-lambda-eracommons-role-template.yaml"
cf_iam_apigateway="iam-apigtw-role-template.yaml"

s3exist=$(aws s3api head-bucket --bucket $s3bucket 2>&1 || true)
if [ -n "${s3exist}" ] 
 then
    echo -e "ERROR: Bucket ${s3bucket} does not exist."
    exit 1
fi

ddb_table_arn=$(aws cloudformation describe-stacks --stack-name ${tier}-edis-ddb --query "Stacks[0].Outputs[?OutputKey=='DdbExtusersArn'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')

aws cloudformation deploy --stack-name ${tier}-edis-iam-lambda-role --template-file "$cf_dir/$cf_iam_lambda" \
                          --s3-bucket ${s3bucket} --s3-prefix app-edis-${tier} \
                          --parameter-overrides \
                            Environment=${tier} --capabilities CAPABILITY_NAMED_IAM

aws cloudformation deploy --stack-name ${tier}-edis-iam-apigtwy-role --template-file "$cf_dir/$cf_iam_apigateway" \
                          --s3-bucket ${s3bucket} --s3-prefix app-edis-${tier} \
                          --parameter-overrides \
                            Environment=${tier} \
                            DdbTableArn=${ddb_table_arn} --capabilities CAPABILITY_NAMED_IAM 

stackStatus=$(aws cloudformation describe-stacks --stack-name ${tier}-edis-iam-apigtwy --query "Stacks[0].StackStatus" | sed -e 's/^"//' -e 's/"$//')
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
