locals {
  tier_conf = tomap({
    dev = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(45 1 * * ? *)"
    }
    dev2 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(55 1 * * ? *)"
    }
    dev3 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(55 1 * * ? *)"
    }
    test = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(15 1 * * ? *)"
    }
    qa = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      step_cron = "cron(20 1 * * ? *)"
    }
    stage = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
      step_cron = "cron(15 1 * * ? *)"
    }
    prod = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
      step_cron = "cron(20 1 * * ? *)"
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

  lambda_generate_ts_api_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ]

  policy-boundary-arn = "arn:aws:iam::${data.aws_caller_identity._.account_id}:policy/PermissionBoundary_PowerUser"
}

# -----------------------------------------------------------------------------
# Data: aws_caller_identity gets data from current AWS account
# -----------------------------------------------------------------------------
data "aws_caller_identity" "_" {}

#data "external" "swagger" {
#  program = ["bash", "-c", <<EOT
#(npm run swagger) >&2 && echo "{\"swagger_file\": \"../out/generate-ts-swagger.yml\"}"
#EOT
#  ]
#  working_dir = "../"
#}

#data "external" "lambda-zip" {
#  depends_on = [data.external.swagger]
#  program = ["bash", "-c", <<EOT
#(npm run zip-prod) >&2 && echo "{\"lambda_zip\": \"../out/generate-ts-swagger.zip\"}"
#EOT
#  ]
#  working_dir = "../"
#}

data "template_file" "api_generate_ts_swagger" {
#  depends_on = [data.external.swagger]
  template = file("../artifacts/generate-ts-swagger.yml")
  vars = {
    lambda_invoke_arn = module.lambda-generate-ts-api.invoke_arn
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

