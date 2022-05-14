resource "aws_iam_policy" "iam_access_ddb" {
  name        = "${var.must-be-role-prefix}-ddb-extusers-read-${var.env}"
  path        = "/"
  description = "Access to given ddb table"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["dynamodb:*"]
        Effect = "Allow"
        Sid    = "ddbPermissions"
        Resource = [
          aws_dynamodb_table.dynamodb.arn,
          "${aws_dynamodb_table.dynamodb.arn}/index/*"
        ]
      }
    ]
  })
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
