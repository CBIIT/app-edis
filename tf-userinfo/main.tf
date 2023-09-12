
module "ddb-userinfo" {
  source              = "./modules/ddb-userinfo"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  resource_tag_name   = "edis"
}

module "lambda-userinfo-api" {
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "userinfo-api"
  file-name           = abspath("../built-artifacts/lambda-user-api/out/lambda-user-api.zip")
  lambda-description  = "Lambda function contains NED and VDS users info REST APIs implementation."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    SECRET    = lookup(local.tier_conf, var.env).secret
  })
  lambda-managed-policies        = { for idx, val in local.lambda_userinfo_api_role_policies: idx => val }
  create_api_gateway_integration = true
  api_gateway_rest_api_id        = module.api-gateway-userinfo.rest_api_id
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
}

resource "aws_iam_role" "invocation_role" {
  name = "${local.power-user-prefix}-apigwy-userinfo-auth-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_api_gateway_service.json
  path = "/"
  permissions_boundary = local.policy-boundary-arn
}
module "api-gateway-userinfo" {
  depends_on = [ module.lambda-userinfo-auth ]
  source              = "../tf-lib/modules/api-gateway"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  app                 = "edis"
  app-description     = "Enterprise Data & Integration Services Web Services for NED and VDS user info"
  api-swagger         = data.template_file.api_userinfo_swagger.rendered
  api-resource-policy = local.api_gateway_resource_policy
  api-gateway-name    = "userinfo"
  resource_tag_name   = "edis"
}

module "lambda-userinfo-auth" {
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "userinfo-auth"
  file-name           = abspath("../built-artifacts/lambda-auth/out/lambda-auth.zip")
  lambda-description  = "Lambda function to run Athena query to get VDS users delta for refresh."
  lambda-env-variables = tomap({
    "LOG_LEVEL" = "info"
    "AUDIENCE"  = "api://default"
    "ISSUER"    = lookup(local.tier_conf, var.env).issuer
    "SECRET"    = lookup(local.tier_conf, var.env).secret

  })
  lambda-managed-policies        = { for idx, val in local.lambda_userinfo_auth_policies: idx => val }
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
  create_api_gateway_integration = false
}

resource "aws_lambda_permission" "_" {
  principal     = "apigateway.amazonaws.com"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda-userinfo-auth.arn

  source_arn = "arn:aws:execute-api:us-east-1:${
    data.aws_caller_identity._.account_id
    }:${
    module.api-gateway-userinfo.rest_api_id
  }/*"
}

module "lambda-vds-users-delta" {
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "vds-users-delta"
  file-name           = abspath("../built-artifacts/lambda-vds-users-delta/out/lambda-vds-users-delta.zip")
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
  depends_on = [aws_iam_policy.iam_access_s3]
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "load-from-vds"
  file-name           = abspath("../built-artifacts/lambda-load-from-vds/out/lambda-load-from-vds.zip")
  lambda-description  = "Lambda function to load VDS users into S3 bucket"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    SECRET    = lookup(local.tier_conf, var.env).secret
    S3BUCKET  = var.s3bucket-for-vds-users
    S3FOLDER  = "app-edis-data-${var.env}/vds/current"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_load_from_vds_role_policies: idx => val }
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
  lambda_timeout = 900
  max-retry = 1
}

module "lambda-prepare-s3-for-vds" {
  depends_on = [aws_iam_policy.iam_access_s3]
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "prepare-s3-for-vds"
  file-name           = abspath("../built-artifacts/lambda-prepare-s3-for-vds/out/lambda-prepare-s3-for-vds.zip")
  lambda-description  = "Lambda function to load VDS users into S3 bucket"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    S3BUCKET  = var.s3bucket-for-vds-users
    S3FOLDER  = "app-edis-data-${var.env}"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_prepare_s3_for_vds_role_policies: idx => val }
}

  module "lambda-vds-delta-to-sqs" {
    depends_on = [aws_iam_policy.iam_access_s3]
    source              = "../tf-lib/modules/lambda"
    env                 = var.env
    must-be-role-prefix = local.power-user-prefix
    must-be-policy-arn  = local.policy-boundary-arn
    resource_tag_name   = "edis"
    region              = "us-east-1"
    app                 = "edis"
    lambda-name         = "vds-delta-to-sqs"
    file-name           = abspath("../built-artifacts/lambda-vds-delta-to-sqs/out/lambda-vds-delta-to-sqs.zip")
    lambda-description  = "Lambda function to send updated VDS user records from S3 bucket into SQS"
    lambda-env-variables = tomap({
      LOG_LEVEL = "info"
      SQS_URL     = "https://sqs.us-east-1.amazonaws.com/${data.aws_caller_identity._.account_id}/edis-vds-delta-queue-${var.env}"
    })
    lambda-managed-policies        = { for idx, val in local.lambda_delta-to-sqs_role_policies: idx => val }
    lambda_timeout = 900
}

  module "lambda-delta-to-sqs" {
    depends_on = [aws_iam_policy.iam_access_s3]
    source              = "../tf-lib/modules/lambda"
    env                 = var.env
    must-be-role-prefix = local.power-user-prefix
    must-be-policy-arn  = local.policy-boundary-arn
    resource_tag_name   = "edis"
    region              = "us-east-1"
    app                 = "edis"
    lambda-name         = "delta-to-sqs"
    file-name           = abspath("../built-artifacts/lambda-delta-to-sqs/out/lambda-delta-to-sqs.zip")
    lambda-description  = "Lambda function to send updated records from S3 bucket into SQS"
    lambda-env-variables = tomap({
      LOG_LEVEL = "info"
      VDS_SQS_URL     = "https://sqs.us-east-1.amazonaws.com/${data.aws_caller_identity._.account_id}/edis-vds-delta-queue-${var.env}"
      NVPROPS_SQS_URL = "https://sqs.us-east-1.amazonaws.com/${data.aws_caller_identity._.account_id}/edis-nv-props-delta-queue-${var.env}"
    })
    lambda-managed-policies        = { for idx, val in local.lambda_delta-to-sqs_role_policies: idx => val }
    lambda_timeout = 900
}

module "lambda-sqs-delta-to-db" {
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  resource_tag_name    = "edis"
  region               = "us-east-1"
  app                  = "edis"
  lambda-name          = "sqs-delta-to-db"
  file-name           = abspath("../built-artifacts/lambda-sqs-batch-to-db/out/lambda-sqs-delta-to-db.zip")
  lambda-description   = "Lambda function to receive updated VDS user records from SQS and load into DynamoDB"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    TABLE     = module.ddb-userinfo.ddb-name
    TABLE_KEY = "NEDId"
    SQS_URL     = "https://sqs.us-east-1.amazonaws.com/${data.aws_caller_identity._.account_id}/edis-vds-delta-queue-${var.env}"
    PURGE_DELETED = "false"
  })
  lambda-managed-policies = {for idx, val in local.lambda_sqs-delta-to-db_role_policies : idx => val}
  lambda_timeout          = 900
}

resource "aws_sqs_queue" "edis-sqs" {
  name                       = "edis-vds-delta-queue-${var.env}"
  visibility_timeout_seconds = 7200
  max_message_size           = 262144
  tags = {
    Tier = var.env
    App = "edis"
  }
}

resource "aws_sqs_queue_policy" "edis-sqs" {
  queue_url = aws_sqs_queue.edis-sqs.id
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
      "Resource": "${aws_sqs_queue.edis-sqs.arn}"
    },
    {
      "Sid": "__sender_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${module.lambda-vds-delta-to-sqs.lambda_role_arn}"
      },
      "Action": "SQS:SendMessage",
      "Resource": "${aws_sqs_queue.edis-sqs.arn}"
    },
    {
      "Sid": "__receiver_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${module.lambda-sqs-delta-to-db.lambda_role_arn}"
      },
      "Action": [
        "SQS:ChangeMessageVisibility",
        "SQS:DeleteMessage",
        "SQS:ReceiveMessage"
      ],
      "Resource": "${aws_sqs_queue.edis-sqs.arn}"
    }
  ]
}
EOF
}

resource "aws_lambda_event_source_mapping" "edis-sqs" {
  batch_size = 2
  event_source_arn = aws_sqs_queue.edis-sqs.arn
  enabled = true
  function_name = module.lambda-sqs-delta-to-db.arn
}

resource "aws_athena_database" "edis-athena" {
  bucket = var.s3bucket-for-vds-users
  name   = "vdsdb_${var.env}"
}

resource "aws_glue_catalog_table" "edis-athena-prev" {
  database_name = aws_athena_database.edis-athena.name
  name          = "prevp_t"
  table_type = "EXTERNAL_TABLE"
  parameters = {
    EXTERNAL = "TRUE"
  }
  storage_descriptor {
    location = "s3://${var.s3bucket-for-vds-users}/app-edis-data-${var.env}/vds/prev/"
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
  database_name = aws_athena_database.edis-athena.name
  name          = "currentp_t"
  table_type = "EXTERNAL_TABLE"
  parameters = {
    EXTERNAL = "TRUE"
  }
  storage_descriptor {
    location = "s3://${var.s3bucket-for-vds-users}/app-edis-data-${var.env}/vds/current/"
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
