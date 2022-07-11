
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
  lambda-managed-policies        = { for idx, val in local.lambda_era_commons_api_role_policies: idx => val }
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
  lambda-managed-policies        = { for idx, val in local.lambda_userinfo_api_role_policies: idx => val }
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

module "lambda-vds-users-delta" {
  source              = "./modules/lambda"
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "vds-users-delta"
  file-name           = "../lambda-zip/lambda-vds-users-delta.zip"
  lambda-description  = "Lambda function to run Athena query to get VDS users delta for refresh."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_vds_users_delta_role_policies: idx => val }
  create_api_gateway_integration = false
}

module "lambda-load-from-vds" {
  source              = "./modules/lambda"
  depends_on = [aws_iam_policy.iam_access_s3]
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "load-from-vds"
  file-name           = "../lambda-zip/lambda-load-from-vds.zip"
  lambda-description  = "Lambda function to load VDS users into S3 bucket"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    SECRET    = "era-commons-connect"
    S3BUCKET  = var.s3bucket-for-vds-users
    S3FOLDER  = "app-edis-data-${var.env}"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_load_from_vds_role_policies: idx => val }
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
  lambda_timeout = 900
  max-retry = 1
}

module "lambda-prepare-s3-for-vds" {
  source              = "./modules/lambda"
  depends_on = [aws_iam_policy.iam_access_s3]
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "prepare-s3-for-vds"
  file-name           = "../lambda-zip/lambda-prepare-s3-for-vds.zip"
  lambda-description  = "Lambda function to load VDS users into S3 bucket"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    S3BUCKET  = var.s3bucket-for-vds-users
    S3FOLDER  = "app-edis-data-${var.env}"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_prepare_s3_for_vds_role_policies: idx => val }
}

module "lambda-vds-delta-to-db" {
  source               = "./modules/lambda"
  depends_on           = [aws_iam_policy.iam_access_s3]
  env                  = var.env
  must-be-role-prefix  = var.role-prefix
  must-be-policy-arn   = var.policy-boundary-arn
  resource_tag_name    = "edis"
  region               = "us-east-1"
  app                  = "edis"
  lambda-name          = "vds-delta-to-db"
  file-name            = "../lambda-zip/lambda-vds-delta-to-db.zip"
  lambda-description   = "Lambda function to load updated VDS user records from S3 bucket into DynamoDB"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    TABLE     = module.ddb-userinfo[0].ddb-name
  })
  lambda-managed-policies = {for idx, val in local.lambda_vds-delta-to-db_role_policies : idx => val}
  lambda_timeout          = 900
}

  module "lambda-vds-delta-to-sqs" {
    source              = "./modules/lambda"
    depends_on = [aws_iam_policy.iam_access_s3]
    env                 = var.env
    must-be-role-prefix = var.role-prefix
    must-be-policy-arn  = var.policy-boundary-arn
    resource_tag_name   = "edis"
    region              = "us-east-1"
    app                 = "edis"
    lambda-name         = "vds-delta-to-sqs"
    file-name           = "../lambda-zip/lambda-vds-delta-to-sqs.zip"
    lambda-description  = "Lambda function to send updated VDS user records from S3 bucket into SQS"
    lambda-env-variables = tomap({
      LOG_LEVEL = "info"
      SQS_URL     = "tbd"
    })
    lambda-managed-policies        = { for idx, val in local.lambda_vds-delta-to-sqs_role_policies: idx => val }
    lambda_timeout = 900
}

module "lambda-sqs-batch-to-db" {
  source               = "./modules/lambda"
  env                  = var.env
  must-be-role-prefix  = var.role-prefix
  must-be-policy-arn   = var.policy-boundary-arn
  resource_tag_name    = "edis"
  region               = "us-east-1"
  app                  = "edis"
  lambda-name          = "sqs-batch-to-db"
  file-name            = "../lambda-zip/lambda-sqs-batch-to-db.zip"
  lambda-description   = "Lambda function to receive updated VDS user records from SQS and load into DynamoDB"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    TABLE     = module.ddb-userinfo[0].ddb-name
    SQS_URL     = "tbd"
  })
  lambda-managed-policies = {for idx, val in local.lambda_sqs-batch-to-db_role_policies : idx => val}
  lambda_timeout          = 900
}

