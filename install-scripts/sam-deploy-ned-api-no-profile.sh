#!/bin/bash

usage() { echo "Usage: $0 [-a <s3bucket>] [-t <tier>] [-s <security group>] [-h]" 1>&2; exit 1; }

s3bucket="cf-templates-107424568411-us-east-1"
tier="dev"
cf_dir="../aws-cf-scripts"

while getopts ha:t:s: opt
do
    case "${opt}" in
        h) usage
          ;;
        a) s3bucket=${OPTARG}
          ;;
        t) tier=${OPTARG}
          ;;
        s) sgroup=${OPTARG}
          ;;
        *) usage
          ;;
    esac
done

s3prefix="app-edis-${tier}"
region="us-east-1"
capabilities="CAPABILITY_IAM"


# cloud team named dev tiers stacks not following the directions
if [ ${tier} = "dev" ]
then
  lambda_role_stack="dev-edis-eracommons-iam-lamba-role"
  apigtwy_role_stack="iam-apigateway-roles"
  secret="era-commons-connect"
else
  lambda_role_stack="${tier}-edis-eracommons-iam-lambda-role"
  apigtwy_role_stack="${tier}-edis-iam-apigtwy-role"
  secret="era-commons-connect-qa"
fi

subnet1=$(aws ec2 describe-subnets  --filter Name=tag:Name,Values=sn-${tier}-db-us-east-1a --profile edis --no-paginate --query "Subnets[0].SubnetId" | sed -e 's/^"//' -e 's/"$//')
subnet2=$(aws ec2 describe-subnets  --filter Name=tag:Name,Values=sn-${tier}-db-us-east-1b --profile edis --no-paginate --query "Subnets[0].SubnetId" | sed -e 's/^"//' -e 's/"$//')
lambda_role_arn=$(aws cloudformation describe-stacks  --stack-name ${lambda_role_stack} --query "Stacks[0].Outputs[?OutputKey=='LambdaOrgapiRoleArn'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')
echo -e "Parameters: $tier $lambda_role_arn ; Subnets: $subnet1 $subnet2 $sgroup"

sam deploy -t $cf_dir/sam-ned-api.yaml --stack-name ${tier}-edis-ned-api --s3-bucket $s3bucket --s3-prefix $s3prefix \
                                    --region $region --no-confirm-changeset --capabilities $capabilities \
                                    --parameter-overrides \
                    Environment=$tier \
                    LambdaRoleArn=$lambda_role_arn \
                    VpcSubnetId1=$subnet1 \
                    VpcSubnetId2=$subnet2 \
                    SgId=$sgroup \
                    Secret=$secret

echo -e "\nServerless Cloud Formation Stack has been deployed"
