#
# The api-gateway module creates api gateway based on a given swagger file
# and includes lambda authorizer for authorization API calls
#

data "aws_caller_identity" "_" {}

resource "aws_api_gateway_rest_api" "api_gateway" {
  name        = "${var.app}-${var.api-gateway-name}-${var.env}"
  description = "${var.env} - ${var.app-description}"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = var.api-swagger
  tags = var.tags
}

resource "aws_api_gateway_deployment" "api_gateway" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id

  triggers = {
    redeployment = sha1(jsonencode([aws_api_gateway_rest_api.api_gateway.body, var.api-resource-policy]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_rest_api_policy" "api_gateway" {
  count       = (var.api-resource-policy != "") ? 1 : 0
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  policy      = var.api-resource-policy
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "${var.app}-${var.api-gateway-name}-apigateway-accesslogs-${var.env}"
  retention_in_days = 90
  tags = var.tags
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
  tags = var.tags
}

resource "aws_api_gateway_method_settings" "api_gateway" {
  method_path = "*/*"
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  stage_name  = aws_api_gateway_stage.api_gateway.stage_name
  settings {
    metrics_enabled      = true
    logging_level        = "INFO"
    data_trace_enabled   = var.trace_enabled
    cache_ttl_in_seconds = 300
    caching_enabled      = var.cache_enabled
  }
}


