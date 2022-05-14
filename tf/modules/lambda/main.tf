
resource "aws_lambda_function" "era_commons_lambda" {
  function_name = "${var.app}-lambda-function-${var.env}"
  description   = var.lambda_description
  filename      = var.lambda_file_location
  handler       = var.lambda_handler_file
  role          = aws_iam_role.iam_for_lambda.arn # TODO
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout

  tracing_config {
    mode = "Active"
  }
  
  environment {
    variables = {
      "LOG_LEVEL" = "info"
      "TABLE"     = var.ddb-table-name
    }
  }
  tags = {
    app = "userinfoapi"
  }
}

resource "aws_lambda_function_event_invoke_config" "era_commons_lambda" {
  function_name          = aws_lambda_function.era_commons_lambda.function_name
  maximum_retry_attempts = 0
}

output "lambda_arn" {
  value = aws_lambda_function.era_commons_lambda.arn
}