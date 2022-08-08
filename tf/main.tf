
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
  file-name           = "../lambda-zip/lambda-eracommons-api.zip"
  lambda-description  = "Lambda function contains eRA Commons External Users Info REST APIs implementation."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    TABLE     = module.ddb-extusers[0].ddb-extusers-name
  })
  lambda-managed-policies        = { for idx, val in local.lambda_era_commons_api_role_policies: idx => val }
  create_api_gateway_integration = true
  api_gateway_rest_api_id        = module.api-gateway-era-commons[0].rest_api_id
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

module "lambda-eracommons" {
  count = (var.build-eracommons) ? 1 : 0
  depends_on          = [module.ddb-extusers]
  source              = "./modules/lambda"
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "era-commons-refresh"
  file-name           = "../lambda-zip/lambda-eracommons.zip"
  lambda-description  = "Lambda function aceeses Oracle eRA Commons and refreshes Dynamo DB table."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    SECRET    = "era-commons-connect-${var.env}"
    TABLE     = module.ddb-extusers[0].ddb-extusers-name
  })
  lambda-managed-policies        = { for idx, val in local.lambda_eracommons_role_policies: idx => val }
  lambda-layers = local.lambda-eracommons-layers
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
}

resource "aws_cloudwatch_event_rule" "edis_refresh_eracommons" {
  count = (var.build-eracommons) ? 1 : 0
  name = "edis-eracommons-refresh-${var.env}"
  description = "Start Lambda Function to refresh eRA Commons user data"
  schedule_expression = "cron(0 12 * * ? *)"
}

resource "aws_cloudwatch_event_target" "edis_refresh_eracommons" {
  count = (var.build-eracommons) ? 1 : 0
  arn  = module.lambda-eracommons[0].arn
  rule = aws_cloudwatch_event_rule.edis_refresh_eracommons[0].name
}

resource "aws_lambda_permission" "edis_refresh_eracommons" {
  count         = var.build-eracommons ? 1 : 0
  principal     = "events.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda-eracommons[0].name
  source_arn = aws_cloudwatch_event_rule.edis_refresh_eracommons[0].arn 
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
  file-name           = "../lambda-zip/lambda-user-api.zip"
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
  count = (var.build-userinfo) ? 1 : 0
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
    S3BUCKET  = var.s3bucket-for-vds-users
    S3FOLDER  = "app-edis-data-${var.env}"
    DB_NAME   = "vdsdb_${var.env}"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_vds_users_delta_role_policies: idx => val }
  create_api_gateway_integration = false
}

module "lambda-load-from-vds" {
  count = (var.build-userinfo) ? 1 : 0
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
  count = (var.build-userinfo) ? 1 : 0
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

  module "lambda-vds-delta-to-sqs" {
    count = (var.build-userinfo) ? 1 : 0
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
      SQS_URL     = "https://sqs.us-east-1.amazonaws.com/${data.aws_caller_identity._.account_id}/edis-vds-delta-queue-${var.env}"
    })
    lambda-managed-policies        = { for idx, val in local.lambda_vds-delta-to-sqs_role_policies: idx => val }
    lambda_timeout = 900
}

module "lambda-sqs-delta-to-db" {
  count = (var.build-userinfo) ? 1 : 0
  source               = "./modules/lambda"
  env                  = var.env
  must-be-role-prefix  = var.role-prefix
  must-be-policy-arn   = var.policy-boundary-arn
  resource_tag_name    = "edis"
  region               = "us-east-1"
  app                  = "edis"
  lambda-name          = "sqs-delta-to-db"
  file-name            = "../lambda-zip/lambda-sqs-delta-to-db.zip"
  lambda-description   = "Lambda function to receive updated VDS user records from SQS and load into DynamoDB"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    TABLE     = module.ddb-userinfo[0].ddb-name
    SQS_URL     = "https://sqs.us-east-1.amazonaws.com/${data.aws_caller_identity._.account_id}/edis-vds-delta-queue-${var.env}"
  })
  lambda-managed-policies = {for idx, val in local.lambda_sqs-delta-to-db_role_policies : idx => val}
  lambda_timeout          = 900
}

resource "aws_sqs_queue" "edis-sqs" {
  count = (var.build-userinfo) ? 1 : 0
  name = "edis-vds-delta-queue-${var.env}"
  visibility_timeout_seconds = 7200
  max_message_size = 262144
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "__default_policy_ID",
  "Statement": [
    {
      "Sid": "__owner_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity._.account_id}:root"
      },
      "Action": "SQS:*",
      "Resource": "arn:aws:sqs:us-east-1:${data.aws_caller_identity._.account_id}:edis-vds-delta-queue-${var.env}"
    },
    {
      "Sid": "__sender_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${module.lambda-vds-delta-to-sqs[0].lambda_role_arn}"
      },
      "Action": "SQS:SendMessage",
      "Resource": "arn:aws:sqs:us-east-1:${data.aws_caller_identity._.account_id}:edis-vds-delta-queue-${var.env}"
    },
    {
      "Sid": "__receiver_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${module.lambda-sqs-delta-to-db[0].lambda_role_arn}"
      },
      "Action": [
        "SQS:ChangeMessageVisibility",
        "SQS:DeleteMessage",
        "SQS:ReceiveMessage"
      ],
      "Resource": "arn:aws:sqs:us-east-1:${data.aws_caller_identity._.account_id}:edis-vds-delta-queue-${var.env}"
    }
  ]
}
EOF
}

resource "aws_lambda_event_source_mapping" "edis-sqs" {
  count = (var.build-userinfo) ? 1 : 0
  batch_size = 2
  event_source_arn = aws_sqs_queue.edis-sqs[0].arn
  enabled = true
  function_name = module.lambda-sqs-delta-to-db[0].arn
}

resource "aws_athena_database" "edis-athena" {
  count = (var.build-userinfo) ? 1 : 0
  bucket = var.s3bucket-for-vds-users
  name   = "vdsdb_${var.env}"
}

resource "aws_glue_catalog_table" "edis-athena-prev" {
  count = (var.build-userinfo) ? 1 : 0
  database_name = aws_athena_database.edis-athena[0].name
  name          = "prevp_t"
  table_type = "EXTERNAL_TABLE"
  parameters = {
    EXTERNAL = "TRUE"
  }
  storage_descriptor {
    location = "s3://${var.s3bucket-for-vds-users}/app-edis-data-${var.env}/prev/"
    input_format = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      name = "my-serde"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = 1
      }
    }
    columns {
      name = "id"
      type = "string"
    }
    columns {
      name = "nihorgpath"
      type = "string"
    }
    columns {
      name = "division"
      type = "string"
    }
    columns {
      name = "content"
      type = "string"
    }
  }
}

resource "aws_glue_catalog_table" "edis-athena-current" {
  count = (var.build-userinfo) ? 1 : 0
  database_name = aws_athena_database.edis-athena[0].name
  name          = "currentp_t"
  table_type = "EXTERNAL_TABLE"
  parameters = {
    EXTERNAL = "TRUE"
  }
  storage_descriptor {
    location = "s3://${var.s3bucket-for-vds-users}/app-edis-data-${var.env}/current/"
    input_format = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      name = "my-serde"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = 1
      }
    }
    columns {
      name = "id"
      type = "string"
    }
    columns {
      name = "nihorgpath"
      type = "string"
    }
    columns {
      name = "division"
      type = "string"
    }
    columns {
      name = "content"
      type = "string"
    }
  }
}

# Global API Gateway resource
resource "aws_iam_role" "api_gateway" {
  count = (!var.build-userinfo && !var.build-eracommons) ? 1 : 0
  name               = "${var.role-prefix}-api-gateway-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_api_gateway_service.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  ]
  path                 = "/"
  permissions_boundary = var.policy-boundary-arn
}

resource "aws_api_gateway_account" "api_gateway" {
  count = (!var.build-userinfo && !var.build-eracommons) ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.api_gateway[0].arn
}

# Global Lambda OracleDB Layer
resource "aws_lambda_layer_version" "oracledb" {
  count = (!var.build-userinfo && !var.build-eracommons) ? 1 : 0
  layer_name = "edis-oracle-db-layer"
  s3_bucket = var.s3bucket-for-vds-users
  s3_key = "api-edis-tf-state/oracledb-layer.zip"
  compatible_runtimes = ["nodejs10.x","nodejs12.x","nodejs14.x"]
  description = "OracleDB lambda layer to connect to Oracle database"
#  source_code_hash = filebase64sha256("../lambda-eracommons/layer/oracledb-layer.zip")
}


