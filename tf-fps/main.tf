
module "lambda-fps-api" {
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  tags                = local.resource_tags
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "fps-api"
  file-name           = abspath("../built-artifacts/lambda-fps-api/out/lambda-fps-api.zip")
  lambda-description  = "Lambda function contains FPS Users Info REST APIs implementation."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    PARAMETER_PATH = "/${var.env}/app/eadis/fps/"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_fps_api_role_policies: idx => val }
  create_api_gateway_integration = true
  api_gateway_rest_api_id        = module.api-gateway-fps.rest_api_id
  lambda-layers = local.lambda-layers
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
  lambda_timeout = 900
  max-retry = 1
}

module "api-gateway-fps" {
  source              = "../tf-lib/modules/api-gateway"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  app                 = "edis"
  app-description     = "Enterprise Data & Integration Services Web Services for FPS users"
  api-swagger         = data.template_file.api_fps-swagger.rendered
  api-resource-policy = local.api_gateway_resource_policy
  api-gateway-name    = "fps"
  tags                = local.resource_tags
}

module "lambda-fps-auth" {
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  tags                = local.resource_tags
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "fps-auth"
  file-name           = abspath("../built-artifacts/lambda-auth/out/lambda-auth.zip")
  lambda-description  = "Lambda function to authorize users to use FPS REST APIs."
  lambda-env-variables = tomap({
    "LOG_LEVEL" = "info"
    "AUDIENCE"  = "api://default"
    "ISSUER"    = lookup(local.tier_conf, var.env).issuer
    "SECRET"    = lookup(local.tier_conf, var.env).secret
  })
  lambda-managed-policies        = { for idx, val in local.lambda_fps_auth_policies: idx => val }
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
  create_api_gateway_integration = false
}

resource "aws_lambda_permission" "_" {
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda-fps-auth.arn

  source_arn = "arn:aws:execute-api:us-east-1:${
    data.aws_caller_identity._.account_id
    }:${
    module.api-gateway-fps.rest_api_id
  }/*"
}

