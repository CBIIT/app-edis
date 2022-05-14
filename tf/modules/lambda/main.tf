
resource "aws_lambda_function" "era_commons_lambda" {
  function_name = join("-", ["lambda-edis-user-api", var.env])
  role          = aws_iam_role.iam_for_lambda.arn # TODO
  description   = "Lambda function contains eRA Commons External Users Info REST APIs implementation."
  handler       = "src/lambda.handler"
  runtime       = "nodejs12.x"
  memory_size   = 2048
  timeout       = 30
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
  filename = "../lambda-zip/lambda-userapi/lambda-userapi.zip"
}

resource "aws_lambda_function_event_invoke_config" "era_commons_lambda" {
  function_name          = aws_lambda_function.era_commons_lambda.function_name
  maximum_retry_attempts = 0
}

output "lambda_arn" {
  value = aws_lambda_function.era_commons_lambda.arn
}