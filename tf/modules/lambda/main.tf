resource "aws_lambda_function" "lambda" {
  function_name = "${var.app}-lambda-function-${var.env}"
  description   = var.lambda_description
  filename      = var.lambda_file_location
  handler       = var.lambda_handler_file
  role          = aws_iam_role.iam_for_lambda.arn # TODO
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  environment {
    variables = {
      "LOG_LEVEL" = var.lambda_log_level
      "TABLE"     = var.ddb-table-name
    }
  }

  tracing_config {
    mode = var.lambda_tracing_mode
  }

  tags = {
    app  = var.app
    tier = var.env
  }
}

resource "aws_lambda_function_event_invoke_config" "lambda" {
  function_name          = aws_lambda_function.lambda.function_name
  maximum_retry_attempts = var.lambda_config_retry_attempts
}

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
  path                 = "/"
  permissions_boundary = var.must-be-policy-arn
}
