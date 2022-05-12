

module "ddb-extusers" {
  source = "./modules/ddb-extusers"
  env = var.env
}

module "lambda" {
  depends_on = [module.ddb-extusers]
  source = "./modules/lambda"
  env = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn = var.policy-boundary-arn
  ddb-table-name = module.ddb-extusers.ddb-extusers-name
}

module "api-gateway" {
  depends_on = [module.ddb-extusers, module.lambda]
  source = "./modules/api-gateway"
  env = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn = var.policy-boundary-arn
  okta-issuer = lookup(local.OktaMap, var.env).issuer
  app-name = "eracommons"
  app-description = "Enterprise Data & Integration Services Web Services"
  api-swagger = data.template_file.api_swagger.rendered
  api-resource-policy = local.resource_policy 
}
