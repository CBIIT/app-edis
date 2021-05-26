#!/bin/bash

usage() { echo "Usage: $0 [-a <account>] [-t <tier>] [-h]" 1>&2; exit 1; }

account="107424568411"
tier="dev"
cf_dir="../aws-cf-scripts"

while getopts ha:t: opt
do
    case "${opt}" in
        h) usage
          ;;
        a) account=${OPTARG}
          ;;
        t) tier=${OPTARG}
          ;;
        *) usage
          ;;
    esac
done

s3bucket="cf-templates-$account-us-east-1"

sam_template="sam-template.yaml"

echo "account = $account, s3 = ${s3bucket}"
echo ""

sname="app-serverless"
s3_bucket="cf-templates-$account-us-east-1"
s3_prefix="userapi-serverless"
region="us-east-1"
capabilities="CAPABILITY_IAM"

vpc_endpoint_id=$(aws cloudformation describe-stacks --stack-name ${tier}-userapi-vpc-endpoint --query "Stacks[0].Outputs[?OutputKey=='VPCEndpointId'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')
lambda_role_arn=$(aws cloudformation describe-stacks --stack-name ${tier}-userapi-iam-lambda --query "Stacks[0].Outputs[?OutputKey=='LambdaOrgapiRoleArn'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')
subnet1=$(aws ec2 describe-subnets --query "Subnets[?AvailabilityZone=='us-east-1a'].SubnetId | [0]" | sed -e 's/^"//' -e 's/"$//')
subnet2=$(aws ec2 describe-subnets --query "Subnets[?AvailabilityZone=='us-east-1b'].SubnetId | [0]" | sed -e 's/^"//' -e 's/"$//')
sg=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='default'].GroupId | [0]" | sed -e 's/^"//' -e 's/"$//')

echo -e "Parameters: $vpc_endpoint_id $lambda_role_arn $subnet1 $subnet2 $sg"

sam deploy -t $cf_dir/$sam_template --stack-name ${tier}-userapi-app-serverless --s3-bucket $s3bucket --s3-prefix $s3prefix --region $region --no-confirm-changeset --capabilities $capabilities --parameter-overrides \
                    ParameterKey=Environment,ParameterValue=$tier \
                    ParameterKey=LambdaRoleArn,ParameterValue=$lambda_role_arn \
                    ParameterKey=VpcEndpointId,ParameterValue=$vpc_endpoint_id \
                    ParameterKey=VpcSubnetId1,ParameterValue=$subnet1 \
                    ParameterKey=VpcSubnetId2,ParameterValue=$subnet2 \
                    ParameterKey=SgId,ParameterValue=$sg

echo -e "\nServerless Cloud Formation Stack has been deployed"

