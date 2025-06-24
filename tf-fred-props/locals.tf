locals {
  tier_conf = tomap({
    dev = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_fred_props_cron = "cron(00 3 * * ? *)"
      secret = "era-commons-connect"
    }
    dev2 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_fred_props_cron = "cron(55 3 * * ? *)"
      secret = "era-commons-connect"
    }
    dev3 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_fred_props_cron = "cron(55 3 * * ? *)"
      secret = "era-commons-connect"
    }
    test = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_fred_props_cron = "cron(15 3 * * ? *)"
      secret = "era-commons-connect-qa"
    }
    qa = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_fred_props_cron = "cron(30 3 * * ? *)"
      secret = "era-commons-connect-qa"
    }
    stage = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
      step_fred_props_cron = "cron(15 3 * * ? *)"
      secret = "era-commons-connect-stage"
    }
    prod = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
      step_fred_props_cron = "cron(30 3 * * ? *)"
      secret = "era-commons-connect-prod"
    }
  })

  api_gateway_resource_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
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
            "156.40.216.73/24",
            "10.133.2.176/24",
            "10.172.0.0/16",
            "10.208.27.100/32",
            "3.219.36.152",
            "18.206.26.93"
          ]
        }
      }
    }
  ]
}
EOF

  lambda_fred_props_auth_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  ]

  lambda_load_from_fred_props_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
    aws_iam_policy.iam_access_s3.arn
  ]

  lambda_prepare_s3_for_fred_props_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    aws_iam_policy.iam_access_s3.arn
  ]

  lambda_fred_props_delta_role_policies = [
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

  power-user-prefix = "power-user-edis"
  policy-boundary-arn = "arn:aws:iam::${data.aws_caller_identity._.account_id}:policy/PermissionBoundary_PowerUser"

  resource_tags = {
    EnvironmentTier = upper(var.env),
    ApplicationName = "Enterprise Administrative Data and Integration Services",
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

data "template_file" "api_fred-props-swagger" {
  template = file("resources/tf-swagger-fred-props-v3.yaml")

  vars = {
    ddb_action_get_item = "arn:aws:apigateway:us-east-1:dynamodb:action/GetItem"
    ddb_action_scan     = "arn:aws:apigateway:us-east-1:dynamodb:action/Scan"
    ddb_action_query    = "arn:aws:apigateway:us-east-1:dynamodb:action/Query"
    ddb_role_arn        = module.ddb-fred-props.iam-access-ddb-role-arn
    table_name          = module.ddb-fred-props.ddb-table-name
    auth_lambda_invoke_arn = module.lambda-fred-props-auth.invoke_arn
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

