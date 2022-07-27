locals {
  OktaMap = tomap({
    dev = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    dev2 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    dev3 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    test = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    qa = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    stage = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
    }
    prod = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
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

  lambda_vds_users_delta_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "arn:aws:iam::aws:policy/AmazonAthenaFullAccess",
    "${aws_iam_policy.iam_access_s3.arn}"
  ]

  lambda_load_from_vds_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
    "${aws_iam_policy.iam_access_s3.arn}"
  ]

  lambda_prepare_s3_for_vds_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "${aws_iam_policy.iam_access_s3.arn}"
  ]

  lambda_vds-delta-to-sqs_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "${aws_iam_policy.iam_access_s3.arn}",
    "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
  ]

  lambda_sqs-delta-to-db_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
  ]
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
  }
}