module "ddb-extusers" {
  source = "./modules/ddb-extusers"
  env = var.env
}

module "lambda" {
  source = "./modules/lambda"
  env = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-name = var.role-policy-name
  ddb-table-arn = module.ddb-extusers.ddb-extusers-arn
}
