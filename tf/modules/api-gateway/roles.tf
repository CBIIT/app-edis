resource "aws_iam_role" "auth_lambda" {
  name                 = "${var.must-be-role-prefix}-lambda-auth-${var.env}"
  assume_role_policy   = data.aws_iam_policy_document.assume_role_lambda_service.json
  path                 = "/"
  permissions_boundary = var.must-be-policy-arn
}

resource "aws_iam_role_policy_attachment" "auth_lambda" {
  role       = aws_iam_role.auth_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "auth_lambda" {
  role       = aws_iam_role.auth_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "auth_lambda" {
  role       = aws_iam_role.auth_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role" "api_gateway" {
  name                 = "${var.must-be-role-prefix}-api-gateway-${var.app}-${var.env}"
  assume_role_policy   = data.aws_iam_policy_document.assume_role_apigateway_service
  path                 = "/"
  permissions_boundary = var.must-be-policy-arn
}

resource "aws_iam_role_policy_attachment" "api_gateway" {
  role       = aws_iam_role.api_gateway.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
