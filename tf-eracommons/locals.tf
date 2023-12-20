locals {
  tier_conf = tomap({
    dev = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(45 1 * * ? *)"
      step_era_commons_cron = "cron(45 2 * * ? *)"
      secret = "era-commons-connect"
    }
    dev2 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(55 1 * * ? *)"
      step_era_commons_cron = "cron(55 2 * * ? *)"
      secret = "era-commons-connect"
    }
    dev3 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(55 1 * * ? *)"
      step_era_commons_cron = "cron(55 2 * * ? *)"
      secret = "era-commons-connect"
    }
    test = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(15 1 * * ? *)"
      step_era_commons_cron = "cron(15 2 * * ? *)"
      secret = "era-commons-connect-qa"
    }
    qa = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(20 1 * * ? *)"
      step_era_commons_cron = "cron(20 2 * * ? *)"
      secret = "era-commons-connect-qa"
    }
    stage = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
      step_cron = "cron(15 1 * * ? *)"
      step_era_commons_cron = "cron(15 2 * * ? *)"
      secret = "era-commons-connect-stage"
    }
    prod = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
      step_cron = "cron(20 1 * * ? *)"
      step_era_commons_cron = "cron(20 2 * * ? *)"
      secret = "era-commons-connect-prod"
    }
  })

  api_gateway_resource_policy = <<EOF
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
            "156.40.216.3/32",
            "156.40.216.1/32",
            "52.115.248.9",
            "149.96.193.8/29",
            "149.96.192.8/29",
            "149.96.193.8/29"
          ]
        }
      }
    }
  ]
}
EOF

  lambda_era_commons_auth_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ]

  lambda_era_commons_api_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  ]

  lambda_load_from_era_commons_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    aws_iam_policy.iam_access_s3.arn
  ]

  lambda_prepare_s3_for_era_commons_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    aws_iam_policy.iam_access_s3.arn
  ]

  lambda_era_commons_delta_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/AmazonAthenaFullAccess",
    aws_iam_policy.iam_access_s3.arn
  ]

  lambda_delta-to-sqs_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    aws_iam_policy.iam_access_s3.arn,
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ]

  lambda_sqs-delta-to-db_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  ]

  lambda-layers = (var.oracle-db-layer-arn != null) ? [
    var.oracle-db-layer-arn
  ] : []

  power-user-prefix = "power-user-edis"
  policy-boundary-arn = "arn:aws:iam::${data.aws_caller_identity._.account_id}:policy/PermissionBoundary_PowerUser"

  resource_tags = {
    EnvironmentTier = upper(var.env),
    ApplicationName = "eRACommons",
    Project = "EADIS",
    Backup = (var.env == "prod") ? "prod" : "nonprod",
    ResourceName = "NCI-EADIS-${var.env}",
    CreateDate = formatdate("MM/DD/YYYY", timestamp()),
    CreatedBy = var.email,
    #    ResourceFunction = "",
    Runtime = "24/7"
  }
}

# -----------------------------------------------------------------------------
# Data: aws_caller_identity gets data from current AWS account
# -----------------------------------------------------------------------------
data "aws_caller_identity" "_" {}

data "template_file" "api_era-commons-swagger" {
  template = file("resources/tf-swagger-era-commons-v3.yaml")

  vars = {
    lambda_invoke_arn   = module.lambda-era-commons-api.invoke_arn
    ddb_action_get_item = "arn:aws:apigateway:us-east-1:dynamodb:action/GetItem"
    ddb_action_scan     = "arn:aws:apigateway:us-east-1:dynamodb:action/Scan"
    ddb_action_query    = "arn:aws:apigateway:us-east-1:dynamodb:action/Query"
    ddb_role_arn        = module.ddb-era-commons.iam-access-ddb-role-arn
    users_table_name    = module.ddb-era-commons.ddb-table-name
    auth_lambda_invoke_arn = module.lambda-era-commons-auth.invoke_arn
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

