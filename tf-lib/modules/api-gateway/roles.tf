#
# IAM roles for Lambda Authorizer and API Gateway
#

data "aws_iam_policy_document" "assume_role_lambda_service" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "auth_lambda" {
  name               = "${var.must-be-role-prefix}-lambda-auth-${var.api-gateway-name}-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda_service.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  ]
  path                 = "/"
  permissions_boundary = var.must-be-policy-arn
  tags = {
    Tier = var.env
    App = var.resource_tag_name
  }
}

