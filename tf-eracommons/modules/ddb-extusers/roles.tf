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

data "aws_iam_policy_document" "iam_access_ddb" {
  statement {
    sid     = "ddbPermissions"
    effect  = "Allow"
    actions = ["dynamodb:*"]
    resources = [
      aws_dynamodb_table.extusers-table.arn,
      "${aws_dynamodb_table.extusers-table.arn}/index/*"
    ]
  }
}

resource "aws_iam_policy" "iam_access_ddb" {
  name        = "${var.must-be-role-prefix}-ddb-extusers-read-${var.env}"
  path        = "/"
  description = "Access to given ddb table"
  policy      = data.aws_iam_policy_document.iam_access_ddb.json
}

resource "aws_iam_role" "iam_access_ddb" {
  name               = "${var.must-be-role-prefix}-api-gateway-extusers-ddb-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_api_gateway_service.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs",
    aws_iam_policy.iam_access_ddb.arn
  ]
  path                 = "/"
  permissions_boundary = var.must-be-policy-arn
}
