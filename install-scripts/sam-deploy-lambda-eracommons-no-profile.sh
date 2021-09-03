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

#subnet1="MUST TO SET subnet1"
#subnet2="MUST TO SET subnet2"
#sgid="MUST BE SET to lambda security group id"

if [ -z ${subnet1+x} ]
then
  echo "ERROR: You must set subnet1, subnet2, and sgid";
  exit 1;
fi

sam_template="sam-lambda-eracommons.yaml"
layer_zip="oracledb-layer.zip"

s3prefix="app-edis-${tier}"
s3zip="${s3prefix}/${layer_zip}"
region="us-east-1"
capabilities="CAPABILITY_IAM"

aws s3 cp "../lambda-eracommons/layer/${layer_zip}" "s3://${s3bucket}/${s3zip}"

lambda_role_arn=$(aws cloudformation describe-stacks  --stack-name ${tier}-edis-eracommons-iam-lamba-role --query "Stacks[0].Outputs[?OutputKey=='LambdaOrgapiRoleArn'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')

echo -e "Parameters: $tier $lambda_role_arn"

sam deploy -t $cf_dir/$sam_template --stack-name ${tier}-edis-lambda-eracommons --s3-bucket $s3bucket --s3-prefix $s3prefix \
                                    --region $region --no-confirm-changeset --capabilities $capabilities \
                                    --parameter-overrides \
                    Environment=$tier \
                    LambdaRoleArn=$lambda_role_arn \
                    S3bucket=$s3bucket \
                    S3zip=$s3zip \
                    VpcSubnetId1=$subnet1 \
                    VpcSubnetId2=$subnet2 \
                    SgId=$sgid

echo -e "\nServerless Cloud Formation Stack has been deployed"
