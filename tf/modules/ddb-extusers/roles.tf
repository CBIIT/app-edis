resource "aws_iam_policy" "iam_access_ddb" {
  name        = "${var.must-be-role-prefix}-${aws_dynamodb_table.dynamodb.name}-policy"
  path        = "/"
  description = "Permits access to the ${aws_dynamodb_table.dynamodb.name} DynamoDB table"
  policy      = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_iam_role" "iam_access_ddb" {
  name = "${var.must-be-role-prefix}-api-gateway-user-api-ddb-${var.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs",
    aws_iam_policy.iam_access_ddb.arn
  ]
  path                 = "/"
  permissions_boundary = var.must-be-policy-arn
}
