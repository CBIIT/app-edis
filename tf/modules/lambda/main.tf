
locals {
  OktaMap = tomap({
    dev = {
      issuer = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    dev2 = {
      issuer = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    test = {
      issuer = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    qa = {
      issuer = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    stage = {
      issuer = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
    }
    prod = {
      issuer = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
    }
  })
  
  table-name = "extusers-${var.env}"
}

resource "aws_lambda_function" "era_commons_lambda" {
  function_name = join("-", ["lambda-edis-user-api", var.env])
  role          = aws_iam_role.iam_for_lambda.arn
  description   = "Lambda function contains eRA Commons External Users Info REST APIs implementation."
  handler = "src/lambda.handler"
  runtime = "nodejs12.x"
  memory_size = 2048
  timeout = 30
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = {
      "LOG_LEVEL" = "info"
      "TABLE"       = "${local.table-name}"
    }
  }
  tags = {
    app = "userinfoapi"
  }
  filename = "../lambda-zip/lambda-userapi/lambda-userapi.zip"
}

resource "aws_lambda_function_event_invoke_config" "ers_commons_lambda_config" {
  function_name = aws_lambda_function.era_commons_lambda.function_name
  maximum_retry_attempts = 0
}


resource "aws_lambda_function" "auth_lambda" {
  function_name = "lambda-auth-${var.env}" 
  role          = aws_iam_role.iam_for_lambda.arn
  description   = "Lambda function with basic authorization."
  handler = "src/lambda.handler"
  runtime = "nodejs12.x"
  memory_size = 2048
  timeout = 30
  tracing_config {
    mode = "Active"
  }
  environment {
    variables = {
      "LOG_LEVEL" = "info"
      "AUDIENCE"  = lookup(local.OktaMap, var.env).audience
      "ISSUER"    = lookup(local.OktaMap, var.env).issuer
    }
  }
  tags = {
    app = "userinfoapi"
  }
  filename = "../lambda-zip/lambda-auth/lambda-auth.zip"
}

resource "aws_lambda_function_event_invoke_config" "auth_lambda_config" {
  function_name = aws_lambda_function.auth_lambda.function_name
  maximum_retry_attempts = 0
}

resource "aws_api_gateway_account" "era_commons_user_api" {
  cloudwatch_role_arn = "${aws_iam_role.iam_for_api_gateway.arn}"
}

resource "aws_api_gateway_rest_api" "era_commons_user_api" {
  name = "eRA Commons User API - ${var.env}"
  description = "${var.env} - Enterprise Data & Integration Services Web Services"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  body = data.template_file.api_swagger.rendered
  
}

data "template_file" "api_swagger" {
  template = file("modules/lambda/tf-swagger-userapi-v3.yaml")

  vars = {
    lambda_arn = "${aws_lambda_function.era_commons_lambda.invoke_arn}"
    ddb_action_get_item = "arn:aws:apigateway:us-east-1:dynamodb:action/GetItem"
    ddb_action_scan = "arn:aws:apigateway:us-east-1:dynamodb:action/Scan"
    ddb_action_query = "arn:aws:apigateway:us-east-1:dynamodb:action/Query"
    ddb_role_arn = "${aws_iam_role.iam_access_ddb.arn}"
    users_table_name = "${local.table-name}"
  }
}

resource "aws_api_gateway_deployment" "era_commons_user_api" {
  rest_api_id = "${aws_api_gateway_rest_api.era_commons_user_api.id}"
  stage_name  = "${var.env}"
}

resource "aws_api_gateway_authorizer" "era_commons_user_api" {
  name        = "era-commons-user-api-authorizer"
  rest_api_id = "${aws_api_gateway_rest_api.era_commons_user_api.id}"
  authorizer_uri = "${aws_lambda_function.auth_lambda.invoke_arn}"
  type = "TOKEN"
}

resource "aws_api_gateway_rest_api_policy" "era_commons_user_api" {
  rest_api_id = aws_api_gateway_rest_api.era_commons_user_api.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "execute-api:Invoke",
      "Resource": "execute-api:/*/*/*"
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "execute-api:/*/*/*",
      "Condition": {
        "NotIpAddress": {
          "aws:SourceIp": [
            "128.231.0.0/16",
            "156.40.216.3/32",
            "156.40.216.1/32",
            "52.115.248.9",
            "149.96.193.8/29",
            "149.96.192.8/29",
            "149.96.193.8/29"
          ]
        }
      }
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "era_commons_user_api" {
  name = "business_apps-${var.env}-edisapi-accesslogs"
  retention_in_days = 90
}

resource "aws_api_gateway_stage" "era_commons_user_api" {
  deployment_id = "${aws_api_gateway_deployment.era_commons_user_api.id}"
  rest_api_id   = "${aws_api_gateway_rest_api.era_commons_user_api.id}"
  stage_name    = "${var.env}"
  cache_cluster_enabled = true
  cache_cluster_size = "1.6"
  access_log_settings {
    destination_arn = "${aws_cloudwatch_log_group.era_commons_user_api.arn}"
    format          = <<EOF
{
          "requestTime": "$context.requestTime",
          "requestId": "$context.requestId",
          "httpMethod": "$context.httpMethod",
          "path": "$context.path",
          "resourcePath": "$context.resourcePath",
          "status": $context.status,
          "responseLatency": $context.responseLatency,
          "xrayTraceId": "$context.xrayTraceId",
          "integrationRequestId": "$context.integration.requestId",
          "functionResponseStatus": "$context.integration.status",
          "integrationLatency": "$context.integration.latency",
          "integrationServiceStatus": "$context.integration.integrationStatus",
          "authorizeResultStatus": "$context.authorize.status",
          "authorizerServiceStatus": "$context.authorizer.status",
          "authorizerLatency": "$context.authorizer.latency",
          "authorizerRequestId": "$context.authorizer.requestId",
          "ip": "$context.identity.sourceIp",
          "userAgent": "$context.identity.userAgent",
          "principalId": "$context.authorizer.principalId",
          "user": "$context.identity.user"
}
EOF
  }
  xray_tracing_enabled = true
}

resource "aws_api_gateway_method_settings" "era_commons_user_api" {
  method_path = "*/*"
  rest_api_id = "${aws_api_gateway_rest_api.era_commons_user_api.id}"
  stage_name  = "${var.env}"
  settings {
    metrics_enabled = true
    logging_level = "INFO"
    data_trace_enabled = true
    cache_data_encrypted = true
    cache_ttl_in_seconds = 300
    caching_enabled = true
  }
}

output "url" {
  value = "${aws_api_gateway_deployment.era_commons_user_api.invoke_url}/api"
}