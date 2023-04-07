#
# The api-gateway module creates api gateway based on a given swagger file
# and includes lambda authorizer for authorization API calls
#


# Lambda Authorizer
resource "aws_lambda_function" "auth_lambda" {
  function_name = "${var.app}-${var.api-gateway-name}-auth-${var.env}"
  role          = aws_iam_role.auth_lambda.arn
  description   = "Lambda function with basic authorization."
  handler       = "src/lambda.handler"
  runtime       = "nodejs12.x"
  memory_size   = 2048
  timeout       = 30
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = {
      "LOG_LEVEL" = var.lambda-log-level
      "AUDIENCE"  = var.okta-audience
      "ISSUER"    = var.okta-issuer
    }
  }
  filename = var.auth_lambda_file_name
  tags = {
    Tier = var.env
    App = var.resource_tag_name
  }
}

resource "aws_lambda_function_event_invoke_config" "auth_lambda" {
  function_name          = aws_lambda_function.auth_lambda.function_name
  maximum_retry_attempts = 0
}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "${var.app}-${var.api-gateway-name}-${var.env}"
  description = "${var.env} - ${var.app-description}"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = var.api-swagger
  tags = {
    Tier = var.env
    App = var.resource_tag_name
  }
}

resource "aws_api_gateway_deployment" "api_gateway" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name = "Stage-snapshot"
}

resource "aws_api_gateway_authorizer" "api_gateway" {
  name           = "request-authorizer"
  rest_api_id    = aws_api_gateway_rest_api.api_gateway.id
  authorizer_uri = aws_lambda_function.auth_lambda.invoke_arn
  type           = "TOKEN"
}

resource "aws_api_gateway_rest_api_policy" "api_gateway" {
  count       = (var.api-resource-policy != "") ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  policy      = var.api-resource-policy
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "${var.app}-${var.api-gateway-name}-apigateway-accesslogs-${var.env}"
  retention_in_days = 90
  tags = {
    Tier = var.env
    App = var.resource_tag_name
  }
}

resource "aws_api_gateway_stage" "api_gateway" {
  deployment_id         = aws_api_gateway_deployment.api_gateway.id
  rest_api_id           = aws_api_gateway_rest_api.api_gateway.id
  stage_name            = var.env
  cache_cluster_enabled = var.cache_enabled
  cache_cluster_size    = (var.cache_enabled) ? var.cache_size : null
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format          = "{ \"requestTime\":  \"$context.requestTime\", \"requestId\": \"$context.requestId\", \"httpMethod\": \"$context.httpMethod\", \"path\": \"$context.path\", \"resourcePath\": \"$context.resourcePath\", \"status\": $context.status, \"responseLatency\": $context.responseLatency, \"xrayTraceId\": \"$context.xrayTraceId\", \"integrationRequestId\": \"$context.integration.requestId\", \"functionResponseStatus\": \"$context.integration.status\", \"integrationLatency\": \"$context.integration.latency\", \"integrationServiceStatus\": \"$context.integration.integrationStatus\", \"authorizeResultStatus\": \"$context.authorize.status\", \"authorizerServiceStatus\": \"$context.authorizer.status\", \"authorizerLatency\": \"$context.authorizer.latency\", \"authorizerRequestId\": \"$context.authorizer.requestId\", \"ip\": \"$context.identity.sourceIp\", \"userAgent\": \"$context.identity.userAgent\", \"principalId\": \"$context.authorizer.principalId\", \"user\": \"$context.identity.user\" }"
  }
  xray_tracing_enabled = true
  tags = {
    Tier = var.env
    App = var.resource_tag_name
  }
}

resource "aws_api_gateway_method_settings" "api_gateway" {
  method_path = "*/*"
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = aws_api_gateway_stage.api_gateway.stage_name
  settings {
    metrics_enabled      = true
    logging_level        = "INFO"
    data_trace_enabled   = true
    cache_data_encrypted = true
    cache_ttl_in_seconds = 300
    caching_enabled      = true
  }
}

