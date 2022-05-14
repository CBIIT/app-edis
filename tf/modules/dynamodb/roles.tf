resource "aws_iam_role" "iam_access_ddb" {
  name                 = "${var.must-be-role-prefix}-api-gateway-user-api-ddb-${var.env}"
  description          = "Placeholder" #Update me
  assume_role_policy   = data.aws_iam_policy_document.dynamodb_assume_role.json
  path                 = "/"
  permissions_boundary = var.must-be-policy-arn
}

resource "aws_iam_policy" "iam_access_ddb" {
  name        = "${var.must-be-role-prefix}-${aws_dynamodb_table.dynamodb.name}-policy"
  path        = "/"
  description = "Permits access to the ${aws_dynamodb_table.dynamodb.name} DynamoDB table"
  policy      = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_iam_role_policy_attachment" "iam_access_ddb" {
  role       = aws_iam_role.iam_access_ddb.name
  policy_arn = aws_iam_policy.iam_access_ddb.arn
}

resource "aws_iam_role_policy_attachment" "apigw_push_cloudwatch_logs" {
  role       = aws_iam_role.iam_access_ddb.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
