
module "lambda-org-nidap-api" {
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  tags                = local.resource_tags
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "org-nidap-api"
  file-name           = abspath("../built-artifacts/lambda-nidap-org-api/out/lambda-nidap-org-api.zip")
  lambda-description  = "Lambda function contains Organization REST APIs implementation with NIDAP as a data feedback."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_org_nidap_api_role_policies: idx => val }
  create_api_gateway_integration = true
  api_gateway_rest_api_id        = module.api-gateway-org-nidap.rest_api_id
}

module "api-gateway-org-nidap" {
  source              = "../tf-lib/modules/api-gateway"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  app                 = "edis"
  app-description     = "Enterprise Data & Integration Services Web Services for Organizations with NIDAP as a data feedback"
  api-swagger         = data.template_file.api_org-nidap-swagger.rendered
  api-resource-policy = local.api_gateway_resource_policy
  api-gateway-name    = "org-nidap"
  tags                = local.resource_tags
}

module "lambda-org-nidap-auth" {
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  tags                = local.resource_tags
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "org-nidap-auth"
  file-name           = abspath("../built-artifacts/lambda-auth/out/lambda-auth.zip")
  lambda-description  = "Lambda function authorizer for API Gateway."
  lambda-env-variables = tomap({
    "LOG_LEVEL" = "info"
    "AUDIENCE"  = "api://default"
    "ISSUER"    = lookup(local.tier_conf, var.env).issuer
    "SECRET"    = lookup(local.tier_conf, var.env).secret
  })
  lambda-managed-policies        = { for idx, val in local.lambda_auth_policies: idx => val }
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
  create_api_gateway_integration = false
}

resource "aws_lambda_permission" "_" {
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda-org-nidap-auth.arn

  source_arn = "arn:aws:execute-api:us-east-1:${
    data.aws_caller_identity._.account_id
    }:${
    module.api-gateway-org-nidap.rest_api_id
  }/*"
}

