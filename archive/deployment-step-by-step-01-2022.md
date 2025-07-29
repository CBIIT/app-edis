
# January 2022 - Deployment instructions to stage tier

#### Prerequisites:

- clone https://github.com/CBIIT/app-edis to your computer
- ensure that AWS configuration (default profile) points to **cbiit-edis-aws-prod** AWS account (see account number in the request ticket)
- ensure that aws and sam CLIs are installed on your computer

 #### Step-by-Step Instructions:

1. Create a IAM role for **SumoLogic Pipeline** (one per AWS account - not per tier!)
   1. Create and deploy **iam-sumologic-role-template** CloudFormation stack using **aws-cf-scripts/iam-sumologic-role-template.yaml** template

2. Switch to **install-scripts folder** and run **./sam-deploy-no-profile.sh** script:

```shell
./sam-deploy-no-profile.sh -t stage -a <s3 bucket>
```

where **\<s3 bucket\>** is a name of S3 bucket - see the request ticket.

3. Switch to **install-scripts folder** and run **./sam-deploy-sumologic-no-profile.sh** script:

```shell
./sam-deploy-sumologic-no-profile.sh -t stage -a <s3 bucket>
```

where **\<s3 bucket\>** is a name of S3 bucket - see the request ticket.