
module "ddb-era-commons" {
  source              = "./modules/ddb-extusers"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
}

module "lambda-era-commons-api" {
  depends_on          = [module.ddb-era-commons]
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "era-commons-api"
  file-name           = abspath("../built-artifacts/lambda-userapi/out/lambda-eracommons-api.zip")
  lambda-description  = "Lambda function contains eRA Commons External Users Info REST APIs implementation."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    TABLE     = module.ddb-era-commons.ddb-table-name
  })
  lambda-managed-policies        = { for idx, val in local.lambda_era_commons_api_role_policies: idx => val }
  create_api_gateway_integration = true
  api_gateway_rest_api_id        = module.api-gateway-era-commons.rest_api_id
}

module "api-gateway-era-commons" {
  depends_on          = [module.ddb-era-commons]
  source              = "../tf-lib/modules/api-gateway"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  app                 = "edis"
  app-description     = "Enterprise Data & Integration Services Web Services for eRA Commons users"
  api-swagger         = data.template_file.api_era-commons-swagger.rendered
  api-resource-policy = local.api_gateway_resource_policy
  api-gateway-name    = "era-commons"
  resource_tag_name   = "edis"
}

module "lambda-era-commons-auth" {
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "era-commons-auth"
  file-name           = abspath("../built-artifacts/lambda-auth/out/lambda-auth.zip")
  lambda-description  = "Lambda function to run Athena query to get VDS users delta for refresh."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    "AUDIENCE"  = "api://default"
    "ISSUER"    = lookup(local.tier_conf, var.env).issuer

  })
  lambda-managed-policies        = { for idx, val in local.lambda_era_commons_auth_policies: idx => val }
  create_api_gateway_integration = false
}

resource "aws_lambda_permission" "_" {
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda-era-commons-auth.arn

  source_arn = "arn:aws:execute-api:us-east-1:${
    data.aws_caller_identity._.account_id
    }:${
    module.api-gateway-era-commons.rest_api_id
  }/*"
}

