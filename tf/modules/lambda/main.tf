
# -----------------------------------------------------------------------------
# Data: aws_caller_identity gets data from current AWS account
# -----------------------------------------------------------------------------

data "aws_caller_identity" "_" {}

resource "aws_cloudwatch_log_group" "lambda" {
  name = "/aws/lambda/${var.app}-${var.lambda-name}-${var.env}"
  retention_in_days = var.log-retention-in-days
}

resource "aws_lambda_function" "lambda" {
  depends_on = [aws_cloudwatch_log_group.lambda]
  function_name = "${var.app}-${var.lambda-name}-${var.env}"
  role          = aws_iam_role.iam_for_lambda.arn
  description   = var.lambda-description
  handler       = "src/lambda.handler"
  runtime       = "nodejs12.x"
  memory_size   = 2048
  timeout       = var.lambda_timeout
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = var.lambda-env-variables
  }
  tags = {
    Tier = var.env
    Name = var.resource_tag_name
  }
  filename = var.file-name
  source_code_hash = filebase64sha256("${var.file-name}")
  vpc_config {
    security_group_ids = var.security_group_ids
    subnet_ids         = var.subnet_ids
  }
  layers = var.lambda-layers
}

resource "aws_lambda_function_event_invoke_config" "lambda" {
  function_name          = aws_lambda_function.lambda.function_name
  maximum_retry_attempts = var.max-retry
}

# -----------------------------------------------------------------------------
# Resources: Lambda API Gateway permission
# -----------------------------------------------------------------------------

resource "aws_lambda_permission" "_" {
  count         = var.create_api_gateway_integration ? 1 : 0
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn

  source_arn = "arn:aws:execute-api:${
    var.region
    }:${
    data.aws_caller_identity._.account_id
    }:${
    var.api_gateway_rest_api_id
  }/*/*"
}
