
resource "null_resource" "swagger" {
  provisioner "local-exec" {
    command = "npm run swagger"
    working_dir = "../"
  }
}

resource "null_resource" "lambda-zip" {
  depends_on = [null_resource.swagger]
  provisioner "local-exec" {
    command = "npm run zip-prod"
    working_dir = "../"
  }
}

module "lambda-generate-ts-api" {
  depends_on = [null_resource.lambda-zip]
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
  depends_on = [null_resource.swagger]
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
  auth_lambda_file_name = "../../lambda-zip/lambda-auth.zip"
}

resource "aws_api_gateway_request_validator" "_" {
  name                        = "example"
  rest_api_id                 = module.api-gateway-generate-ts.rest_api_id
  validate_request_body       = true
  validate_request_parameters = true
}
