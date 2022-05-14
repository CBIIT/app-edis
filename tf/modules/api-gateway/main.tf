#
# The api-gateway module creates api gateway based on a given swagger file
# and includes lambda authorizer for authorization API calls
#


# Lambda Authorizer
resource "aws_lambda_function" "auth_lambda" {
  function_name = "${var.app}-lambda-auth-${var.env}"
  role          = aws_iam_role.auth_lambda.arn
  description   = "Lambda function with basic authorization."
  handler       = var.lambda_handler_file
  runtime       = var.lambda_runtime
  memory_size   = var.lambda_memory_size
  timeout       = var.timeout
  filename      = var.lambda_file_location

  tracing_config {
    mode = var.lambda_tracing_mode
  }

  environment {
    variables = {
      "LOG_LEVEL" = var.lambda_log_level
      "AUDIENCE"  = var.okta-audience
      "ISSUER"    = var.okta-issuer
    }
  }

  tags = {
    app = var.app
  }
}

resource "aws_lambda_function_event_invoke_config" "auth_lambda" {
  function_name          = aws_lambda_function.auth_lambda.function_name
  maximum_retry_attempts = var.lambda_config_retry_attempts
}

resource "aws_api_gateway_account" "api_gateway" {
  cloudwatch_role_arn = aws_iam_role.api_gateway.arn
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "${var.app-name} - ${var.env}"
  description = "${var.env} - ${var.app-description}"

  endpoint_configuration {
    types = [var.apigw_endpoint_config]
  }
  body = var.api-swagger
}

resource "aws_api_gateway_deployment" "api_gateway" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
}

resource "aws_api_gateway_authorizer" "api_gateway" {
  name           = "${var.app}-lambda-authorizer-${var.env}"
  rest_api_id    = aws_api_gateway_rest_api.api_gateway.id
  authorizer_uri = aws_lambda_function.auth_lambda.invoke_arn
  type           = var.authorizer_type
}

resource "aws_api_gateway_rest_api_policy" "api_gateway" {
  count = (var.api-resource-policy != "") ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  policy      = var.api-resource-policy
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "${var.portfolio}-${var.env}-${var.app}-accesslogs"
  retention_in_days = var.cloudwatch_log_retention_days
}

resource "aws_api_gateway_stage" "api_gateway" {
  deployment_id         = aws_api_gateway_deployment.api_gateway.id
  rest_api_id           = aws_api_gateway_rest_api.api_gateway.id
  stage_name            = var.env
  cache_cluster_enabled = var.apigw_stage_cache_enabled
  cache_cluster_size    = var.apigw_stage_cache_size
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format          = "{ \"requestTime\":  \"$context.requestTime\", \"requestId\": \"$context.requestId\", \"httpMethod\": \"$context.httpMethod\", \"path\": \"$context.path\", \"resourcePath\": \"$context.resourcePath\", \"status\": $context.status, \"responseLatency\": $context.responseLatency, \"xrayTraceId\": \"$context.xrayTraceId\", \"integrationRequestId\": \"$context.integration.requestId\", \"functionResponseStatus\": \"$context.integration.status\", \"integrationLatency\": \"$context.integration.latency\", \"integrationServiceStatus\": \"$context.integration.integrationStatus\", \"authorizeResultStatus\": \"$context.authorize.status\", \"authorizerServiceStatus\": \"$context.authorizer.status\", \"authorizerLatency\": \"$context.authorizer.latency\", \"authorizerRequestId\": \"$context.authorizer.requestId\", \"ip\": \"$context.identity.sourceIp\", \"userAgent\": \"$context.identity.userAgent\", \"principalId\": \"$context.authorizer.principalId\", \"user\": \"$context.identity.user\" }"
  }
  xray_tracing_enabled = var.apigw_stage_xray_enabled
}

resource "aws_api_gateway_method_settings" "api_gateway" {
  method_path = var.apigw_method_path
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = aws_api_gateway_stage.api_gateway.stage_name

  settings {
    metrics_enabled      = var.apigw_method_metrics_enabled
    logging_level        = var.apigw_method_log_level
    data_trace_enabled   = var.apigw_method_trace_enabled
    cache_data_encrypted = var.apigw_method_cache_encryption
    cache_ttl_in_seconds = var.apigw_method_cache_ttl
    caching_enabled      = var.apigw_method_cache_enabled
  }
}
