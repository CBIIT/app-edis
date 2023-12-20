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
      aws_dynamodb_table.table.arn,
      "${aws_dynamodb_table.table.arn}/index/*"
    ]
  }
}

resource "aws_iam_policy" "iam_access_ddb" {
  name        = "${var.must-be-role-prefix}-ddb-${var.table_name}-read-${var.env}"
  path        = "/"
  description = "Access to given ddb table"
  policy      = data.aws_iam_policy_document.iam_access_ddb.json
  tags        = var.tags
}

resource "aws_iam_role" "iam_access_ddb" {
  name               = "${var.must-be-role-prefix}-api-gateway-${var.table_name}-ddb-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_api_gateway_service.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs",
    aws_iam_policy.iam_access_ddb.arn
  ]
  path                 = "/"
  permissions_boundary = var.must-be-policy-arn
  tags = var.tags
}
