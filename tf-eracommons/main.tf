
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

module "lambda-era-commons" {
  depends_on          = [module.ddb-era-commons]
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "era-commons-refresh"
  file-name           = abspath("../built-artifacts/lambda-eracommons/out/lambda-eracommons.zip")
  lambda-description  = "Lambda function aceeses Oracle eRA Commons and refreshes Dynamo DB table."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    SECRET    = lookup(local.tier_conf, var.env).secret
    TABLE     = module.ddb-era-commons.ddb-table-name
  })
  lambda-managed-policies        = { for idx, val in local.lambda_era_commons_role_policies: idx => val }
  lambda-layers = local.lambda-layers
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
}

resource "aws_cloudwatch_event_rule" "edis_refresh_eracommons" {
  name = "edis-era-commons-refresh-${var.env}"
  description = "Start Lambda Function to refresh eRA Commons user data"
  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "edis_refresh_eracommons" {
  arn  = module.lambda-era-commons.arn
  rule = aws_cloudwatch_event_rule.edis_refresh_eracommons.name
}

resource "aws_lambda_permission" "edis_refresh_eracommons" {
  principal     = "events.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda-era-commons.name
  source_arn = aws_cloudwatch_event_rule.edis_refresh_eracommons.arn 
}
