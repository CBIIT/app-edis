locals {
  tier_conf = tomap({
    dev = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      secret = "era-commons-connect"
    }
    dev2 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      secret = "era-commons-connect"
    }
    dev3 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      secret = "era-commons-connect"
    }
    test = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      secret = "era-commons-connect-qa"
    }
    qa = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
      secret = "era-commons-connect-qa"
    }
    stage = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
      secret = "era-commons-connect-stage"
    }
    prod = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
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

  lambda_fps_auth_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess",
    "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
  ]

  lambda_fps_api_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  ]

  lambda-layers = (var.oracle-db-layer-arn != null) ? [
    var.oracle-db-layer-arn
  ] : []

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

data "template_file" "api_fps-swagger" {
  template = file("resources/tf-swagger-fps-v3.yaml")

  vars = {
    lambda_invoke_arn   = module.lambda-fps-api.invoke_arn
    auth_lambda_invoke_arn = module.lambda-fps-auth.invoke_arn
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

