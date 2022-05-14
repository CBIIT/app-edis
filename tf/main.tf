

module "dynamodb" {
  source = "./modules/dynamodb"
  env    = var.env
}

module "lambda" {
  depends_on = [module.dynamodb]

  source              = "./modules/lambda"
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
  ddb-table-name      = module.dynamodb.dynamodb_table_name
}

module "api-gateway" {
  depends_on = [module.dynamodb, module.lambda]

  source              = "./modules/api-gateway"
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
  okta-issuer         = lookup(local.OktaMap, var.env).issuer
  app-name            = "eracommons"
  app-description     = "Enterprise Data & Integration Services Web Services"
  api-swagger         = data.template_file.api_swagger.rendered
  api-resource-policy = local.resource_policy
}
