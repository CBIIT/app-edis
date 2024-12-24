
module "ddb-fred-props" {
  source              = "./modules/ddb-fred-props"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  tags = local.resource_tags
}

module "api-gateway-fred-props" {
  depends_on          = [module.ddb-fred-props]
  source              = "../tf-lib/modules/api-gateway"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  app                 = "edis"
  app-description     = "Enterprise Data & Integration Services Web Services for Frederick Properites"
  api-swagger         = data.template_file.api_fred-props-swagger.rendered
  api-resource-policy = local.api_gateway_resource_policy
  api-gateway-name    = "fred-props"
  tags                = local.resource_tags
}

module "lambda-fred-props-auth" {
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  tags                = local.resource_tags
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "fred-props-auth"
  file-name           = abspath("../built-artifacts/lambda-auth/out/lambda-auth.zip")
  lambda-description  = "Lambda function to authorize API Gateway for Frederick Properties."
  lambda-env-variables = tomap({
    "LOG_LEVEL" = "info"
    "AUDIENCE"  = "api://default"
    "ISSUER"    = lookup(local.tier_conf, var.env).issuer
    "SECRET"    = lookup(local.tier_conf, var.env).secret
  })
  lambda-managed-policies        = { for idx, val in local.lambda_fred_props_auth_policies: idx => val }
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
  create_api_gateway_integration = false
}

resource "aws_lambda_permission" "_" {
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda-fred-props-auth.arn

  source_arn = "arn:aws:execute-api:us-east-1:${
    data.aws_caller_identity._.account_id
    }:${
    module.api-gateway-fred-props.rest_api_id
  }/*"
}

