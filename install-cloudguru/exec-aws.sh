#!/bin/bash

usage() { echo "Usage: $0 [-a <account>] [-t <tier>] [-h]" 1>&2; exit 1; }

account="107424568411"
tier="dev"
w_ec2="n"
cf_dir="../aws-cf-scripts"

while getopts ha:t:e: opt
do
    case "${opt}" in
        h) usage
          ;;
        a) account=${OPTARG}
          ;;
        t) tier=${OPTARG}
          ;;
        e)
          if [[ ${OPTARG} = "yes" || ${OPTARG} = "y" ]]
          then w_ec2="y"
          else w_ec2="n"
          fi
          ;;
        *) usage
          ;;
    esac
done

s3bucket="cf-templates-$account-us-east-1"

cf_ec2="ec2-serverless-template.yaml"
cf_ddb="ddb-serverless-template.yaml"
cf_iam_lambda="iam-lambda-role-template.yaml"
cf_iam_apigateway="iam-apigtw-role-template.yaml"
cf_vpc="vpc-endpoint-template.yaml"
keypair=../pgmSSHKey.pem

echo "account = $account, s3 = ${s3bucket}"
echo ""
aws s3api create-bucket --bucket "$s3bucket" --region us-east-1
if [[ ${w_ec2} = "y" ]]
then
  aws s3 cp "$cf_ec2" "s3://$s3bucket"
fi
aws s3 cp "$cf_dir/$cf_ddb" "s3://$s3bucket"
aws s3 cp "$cf_dir/$cf_iam_lambda" "s3://$s3bucket"
aws s3 cp "$cf_dir/$cf_iam_apigateway" "s3://$s3bucket"
aws s3 cp "$cf_dir/$cf_vpc" "s3://$s3bucket"

#get current VPC id
vpcid=$(aws ec2 describe-vpcs --query Vpcs[0].VpcId | sed -e 's/^"//' -e 's/"$//')
echo VPC id = $vpcid

#get us-east-1a Subnet id
subnetid=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=us-east-1a" --query "Subnets[0].SubnetId" | sed -e 's/^"//' -e 's/"$//')
echo Subnet id = $subnetid

aws cloudformation create-stack --stack-name ${tier}-userapi-iam-lambda --template-url "https://${s3bucket}.s3.amazonaws.com/${cf_iam_lambda}" --parameters ParameterKey=Environment,ParameterValue=${tier} --capabilities CAPABILITY_NAMED_IAM
aws cloudformation create-stack --stack-name ${tier}-userapi-iam-apigtwy --template-url "https://${s3bucket}.s3.amazonaws.com/${cf_iam_apigateway}" --parameters ParameterKey=Environment,ParameterValue=${tier} --capabilities CAPABILITY_NAMED_IAM
aws cloudformation create-stack --stack-name ${tier}-userapi-ddb --template-url "https://${s3bucket}.s3.amazonaws.com/${cf_ddb}" --parameters ParameterKey=Environment,ParameterValue=${tier}
aws cloudformation create-stack --stack-name ${tier}-userapi-vpc-endpoint --template-url "https://${s3bucket}.s3.amazonaws.com/${cf_vpc}" --parameters ParameterKey=VpcId,ParameterValue=$vpcid ParameterKey=SubnetId,ParameterValue=$subnetid

websgid=null
while [ ${websgid} == null ]; do
    sleep 2s
    echo -n "."
    websgid=$(aws cloudformation describe-stacks --stack-name ${tier}-userapi-vpc-endpoint --query "Stacks[0].Outputs[?OutputKey=='WebSGId'].OutputValue | [0]" | sed -e 's/^"//' -e 's/"$//')
done

if [[ ${w_ec2} = "y" ]]
then
  rm -f $keypair
  aws ec2 create-key-pair --key-name pgmSSHKey --query 'KeyMaterial' --output text >$keypair
  chmod 400 $keypair

  aws cloudformation create-stack --stack-name ${tier}-ec2-serverless --template-url "https://${s3bucket}.s3.amazonaws.com/${cf_ec2}" --parameters ParameterKey=VpcId,ParameterValue=$vpcid ParameterKey=SubnetId,ParameterValue=$subnetid ParameterKey=WebSGId,ParameterValue=$websgid
  echo -n "Creating stacks..."
  webserver=null
  while [ ${webserver} == null ]; do
      sleep 2s
      echo -n "."
      webserver=$(aws cloudformation describe-stacks --stack-name ${dev}-ec2-serverless --query "Stacks[0].Outputs[?OutputKey=='WebServer'].OutputValue | [0]")
  done
  echo -e "\nWeb server has been created."
  echo -e "\nTo SSH to the web server use the following command:"
  echo -e "      ssh -i \"$keypair\" ec2-user@$webserver"
  echo -e "To copy file to the web server use the following command:"
  echo -e "      scp -i \"$keypair\" <local file> ec2-user@$webserver:<remote folder>"
else
  echo -e "\nCloud Formation Stacks have been deployed"
fi

