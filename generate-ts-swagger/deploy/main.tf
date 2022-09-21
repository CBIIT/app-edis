
module "lambda-generate-ts-api" {
  source              = "../../tf/modules/lambda"
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "generate-ts-api"
  file-name           = "../out/generate-ts-swagger.zip"
  lambda-description  = "Lambda function contains NED REST APIs implementation using Typescript."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    SECRET    = "era-commons-connect"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_generate_ts_api_role_policies: idx => val }
  create_api_gateway_integration = true
  api_gateway_rest_api_id        = module.api-gateway-generate-ts.rest_api_id
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
}

module "api-gateway-generate-ts" {
  source              = "../../tf/modules/api-gateway"
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  okta-issuer         = lookup(local.tier_conf, var.env).issuer
  app                 = "edis"
  app-description     = "Enterprise Data & Integration Services Web Services for NED w Typescript"
  api-swagger         = data.template_file.api_generate_ts_swagger.rendered
  api-resource-policy = local.era_commons_resource_policy
  api-gateway-name    = "generatets"
  resource_tag_name   = "edis"
}

resource "aws_api_gateway_request_validator" "_" {
  name                        = "example"
  rest_api_id                 = module.api-gateway-generate-ts.rest_api_id
  validate_request_body       = true
  validate_request_parameters = true
}

locals {
  endpoints = [
    "/generatets/v1/ned/changesByIc/{ic}"
  ]
}

resource "aws_api_gateway_resource" "generate_ts" {
  for_each = { for idx, val in local.endpoints: idx => val }
  parent_id   = module.api-gateway-generate-ts.root_resource_id
  path_part   = each.value
  rest_api_id = module.api-gateway-generate-ts.rest_api_id
}

resource "aws_api_gateway_method" "generate_ts" {
  for_each = { for idx, val in local.endpoints: idx => val }
  rest_api_id = module.api-gateway-generate-ts.rest_api_id
  resource_id = aws_api_gateway_resource.generate_ts[each.key].id
  authorization = "NONE"
  http_method = "GET"
}

resource "aws_api_gateway_integration" "generate_ts" {
  for_each = { for idx, val in local.endpoints: idx => val }
  http_method = aws_api_gateway_method.generate_ts[each.key].http_method
  resource_id = aws_api_gateway_resource.generate_ts[each.key].id
  rest_api_id = module.api-gateway-generate-ts.rest_api_id
  type        = "AWS_PROXY"
  integration_http_method = "POST"
  uri = module.lambda-generate-ts-api.invoke_arn
  timeout_milliseconds = 29000
}

resource "aws_lambda_permission" "generate_ts" {
  for_each = { for idx, val in local.endpoints: idx => val }
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda-generate-ts-api.name
  principal     = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:us-east-1:${data.aws_caller_identity._.account_id}:${module.api-gateway-generate-ts.rest_api_id}/*/${aws_api_gateway_method.generate_ts[each.key].http_method}${aws_api_gateway_resource.generate_ts[each.key].path}"
}