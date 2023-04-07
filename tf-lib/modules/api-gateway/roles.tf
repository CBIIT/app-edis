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

