
resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.must-be-role-prefix}-lambda-user-api-${var.env}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  ]
  path = "/"
  permissions_boundary = var.must-be-policy-arn
  tags = {
    app = "userinfoapi"
  }
}

resource "aws_iam_role" "iam_for_api_gateway" {
  name = "${var.must-be-role-prefix}-api-gateway-user-api-${var.env}"
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
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  ]
  path = "/"
  permissions_boundary = var.must-be-policy-arn
  tags = {
    app = "userinfoapi"
  }
}

resource "aws_iam_policy" "iam_access_ddb" {
  name = "ddb-extusers-read-${var.env}"
  path = "/"
  description = "Access to given ddb table"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["dynamodb:*"]
        Effect = "Allow"
        Sid    = "ddbPermissions"
        Resource = [
          var.ddb-table-arn,
          "${var.ddb-table-arn}/index/*"
        ]
      }
    ]
  })
  tags = {
    app = "userinfoapi"
  }
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
#  inline_policy {
#    name = "ddb-extusers-read-${var.env}"
#    policy = jsonencode({
#      Version = "2012-10-17"
#      Statement = [
#        {
#          Action = ["dynamodb:*"]
#          Effect = "Allow"
#          Sid    = "ddbPermissions"
#          Resource = [
#            var.ddb-table-arn,
#            "${var.ddb-table-arn}/index/*"
#          ]
#        }
#      ]
#    })
#  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs",
    aws_iam_policy.iam_access_ddb.arn
  ]
  path = "/"
  permissions_boundary = var.must-be-policy-arn
  tags = {
    app = "userinfoapi"
  }
}

