locals {
  tier_conf = tomap({
    dev = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(45 1 * * ? *)"
      step_nv_props_cron = "cron(45 2 * * ? *)"
      secret = "era-commons-connect"
    }
    dev2 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(55 1 * * ? *)"
      step_nv_props_cron = "cron(55 2 * * ? *)"
      secret = "era-commons-connect"
    }
    dev3 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(55 1 * * ? *)"
      step_nv_props_cron = "cron(55 2 * * ? *)"
      secret = "era-commons-connect"
    }
    test = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(15 1 * * ? *)"
      step_nv_props_cron = "cron(15 2 * * ? *)"
      secret = "era-commons-connect-qa"
    }
    qa = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(20 1 * * ? *)"
      step_nv_props_cron = "cron(20 2 * * ? *)"
      secret = "era-commons-connect-qa"
    }
    stage = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
      step_cron = "cron(15 1 * * ? *)"
      step_nv_props_cron = "cron(15 2 * * ? *)"
      secret = "era-commons-connect-stage"
    }
    prod = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
      step_cron = "cron(20 1 * * ? *)"
      step_nv_props_cron = "cron(20 2 * * ? *)"
      secret = "era-commons-connect-prod"
    }
  })

  era_commons_resource_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "execute-api:Invoke",
      "Resource": "execute-api:/*/*/*"
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "execute-api:/*/*/*",
      "Condition": {
        "NotIpAddress": {
          "aws:SourceIp": [
            "128.231.0.0/16",
            "156.40.0.0/16",
            "52.115.248.9",
            "149.96.193.8/29",
            "149.96.192.8/29",
            "149.96.193.8/29",
            "3.219.36.152",
            "18.206.26.93"
          ]
        }
      }
    }
  ]
}
EOF

  lambda_era_commons_api_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  ]

  lambda_userinfo_api_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ]

  lambda_vds_users_delta_role_policies = (var.build-userinfo) ? [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/AmazonAthenaFullAccess",
    aws_iam_policy.iam_access_s3[0].arn
  ] : []

  lambda_load_from_vds_role_policies = (var.build-userinfo) ? [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    aws_iam_policy.iam_access_s3[0].arn
  ] : []

  lambda_prepare_s3_for_vds_role_policies = (var.build-userinfo) ? [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    aws_iam_policy.iam_access_s3[0].arn
  ] : []

  lambda_delta-to-sqs_role_policies = (var.build-userinfo) ? [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    aws_iam_policy.iam_access_s3[0].arn,
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ] : []

  lambda_sqs-delta-to-db_role_policies = (var.build-userinfo) ? [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  ] : []

  lambda_eracommons_role_policies = (var.build-eracommons) ? [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    module.ddb-extusers[0].iam-access-ddb-policy-arn
  ] : []
  

  lambda-eracommons-layers = (var.oracle-db-layer-arn != null) ? [
    var.oracle-db-layer-arn
  ] : []
}

# -----------------------------------------------------------------------------
# Data: aws_caller_identity gets data from current AWS account
# -----------------------------------------------------------------------------
data "aws_caller_identity" "_" {}

data "template_file" "api_era-commons-swagger" {
  template = file("resources/tf-swagger-era-commons-v3.yaml")
  count = (var.build-eracommons) ? 1 : 0

  vars = {
    lambda_invoke_arn   = module.lambda-era-commons-api[0].invoke_arn
    ddb_action_get_item = "arn:aws:apigateway:us-east-1:dynamodb:action/GetItem"
    ddb_action_scan     = "arn:aws:apigateway:us-east-1:dynamodb:action/Scan"
    ddb_action_query    = "arn:aws:apigateway:us-east-1:dynamodb:action/Query"
    ddb_role_arn        = module.ddb-extusers[0].iam-access-ddb-role-arn
    users_table_name    = module.ddb-extusers[0].ddb-extusers-name
  }
}

data "template_file" "api_userinfo_swagger" {
  template = file("resources/swagger-ned-vds-v3.yaml")
  count = (var.build-userinfo) ? 1 : 0

  vars = {
    lambda_invoke_arn = module.lambda-userinfo-api[0].invoke_arn
    ddb_action_scan     = "arn:aws:apigateway:us-east-1:dynamodb:action/Scan"
    ddb_action_query    = "arn:aws:apigateway:us-east-1:dynamodb:action/Query"
    ddb_role_arn        = module.ddb-userinfo[0].iam-access-ddb-role-arn
    prop_ddb_role_arn   = module.ddb-userinfo[0].iam-access-nv-props-ddb-role-arn
    users_table_name    = module.ddb-userinfo[0].ddb-name
    props_table_name    = module.ddb-userinfo[0].nv-props-ddb-name
  }
}

data "aws_iam_policy_document" "assume_role_api_gateway_service" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

