
module "ddb-extusers" {
  count = (var.build-eracommons) ? 1 : 0
  source              = "./modules/ddb-extusers"
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
}

module "lambda-era-commons-api" {
  count = (var.build-eracommons) ? 1 : 0
  depends_on          = [module.ddb-extusers]
  source              = "./modules/lambda"
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "era-commons-api"
  file-name           = "../lambda-zip/lambda-userapi/lambda-userapi.zip"
  lambda-description  = "Lambda function contains eRA Commons External Users Info REST APIs implementation."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    TABLE     = module.ddb-extusers[0].ddb-extusers-name
  })
  lambda-managed-policies        = local.lambda_era_commons_api_role_policies
  create_api_gateway_integration = true
  api_gateway_rest_api_id        = module.api-gateway-era-commons[0].rest_api_id
}

module "ddb-userinfo" {
  count = (var.build-userinfo) ? 1 : 0
  source              = "./modules/ddb-userinfo"
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
}

module "lambda-userinfo-api" {
  count = (var.build-userinfo) ? 1 : 0
  source              = "./modules/lambda"
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "userinfo-api"
  file-name           = "../lambda-zip/lambda-user-api/lambda-user-api.zip"
  lambda-description  = "Lambda function contains NED and VDS users info REST APIs implementation."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    SECRET    = "era-commons-connect"
  })
  lambda-managed-policies        = local.lambda_userinfo_api_role_policies
  create_api_gateway_integration = true
  api_gateway_rest_api_id        = module.api-gateway-userinfo[0].rest_api_id
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
}

module "api-gateway-era-commons" {
  count = (var.build-eracommons) ? 1 : 0
  depends_on          = [module.ddb-extusers]
  source              = "./modules/api-gateway"
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
  okta-issuer         = lookup(local.OktaMap, var.env).issuer
  app                 = "edis"
  app-description     = "Enterprise Data & Integration Services Web Services for eRA Commons users"
  api-swagger         = data.template_file.api_era-commons-swagger[0].rendered
  api-resource-policy = local.era_commons_resource_policy
  api-gateway-name    = "era-commons"
  resource_tag_name   = "edis"
}

module "api-gateway-userinfo" {
  count = (var.build-userinfo) ? 1 : 0
  source              = "./modules/api-gateway"
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
  okta-issuer         = lookup(local.OktaMap, var.env).issuer
  app                 = "edis"
  app-description     = "Enterprise Data & Integration Services Web Services for NED and VDS user info"
  api-swagger         = data.template_file.api_userinfo_swagger[0].rendered
  api-resource-policy = local.era_commons_resource_policy
  api-gateway-name    = "userinfo"
  resource_tag_name   = "edis"
}
