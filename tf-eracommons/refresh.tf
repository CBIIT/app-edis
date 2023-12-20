# Resources to refresh era-commons dynamodb table
#
# Lambda - Load properties records from nVision into S3 bucket storage.parquet file
#
module "lambda-load-from-era-commons" {
  source              = "../tf-lib/modules/lambda"
  depends_on          = [aws_iam_policy.iam_access_s3]
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  tags                = local.resource_tags
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "load-from-era-commons"
  file-name           = abspath("../built-artifacts/lambda-load-from-eracommons/out/lambda-load-from-eracommons.zip")
  lambda-description  = "Lambda function to load Users into from eRA Commons into S3 bucket"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    SECRET    = lookup(local.tier_conf, var.env).secret
    S3BUCKET  = var.s3bucket-for-era-commons-users
    S3FOLDER  = "app-edis-data-${var.env}/era-commons/current"
    S3FILE  = "storage.parquet"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_load_from_era_commons_role_policies: idx => val }
  lambda-layers = local.lambda-layers
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
  lambda_timeout = 900
  max-retry = 1
}

module "lambda-prepare-s3-for-era-commons" {
  depends_on = [aws_iam_policy.iam_access_s3]
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  tags                = local.resource_tags
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "prepare-s3-for-era-commons"
  file-name           = abspath("../built-artifacts/lambda-prepare-s3-for-vds/out/lambda-prepare-s3-for-vds.zip")
  lambda-description  = "Lambda function to prepare S3 bucket folders for data loading"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    S3BUCKET  = var.s3bucket-for-era-commons-users
    S3FOLDER  = "app-edis-data-${var.env}"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_prepare_s3_for_era_commons_role_policies: idx => val }
}

module "lambda-era-commons-delta" {
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  tags                = local.resource_tags
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "era-commons-delta"
  file-name           = abspath("../built-artifacts/lambda-vds-users-delta/out/lambda-vds-users-delta.zip")
  lambda-description  = "Lambda function to run Athena query to get eRA Commons users delta for refresh."
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    S3BUCKET  = var.s3bucket-for-era-commons-users
    S3FOLDER  = "app-edis-data-${var.env}"
    DB_NAME   = "vdsdb_${var.env}"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_era_commons_delta_role_policies: idx => val }
  create_api_gateway_integration = false
}

module "lambda-era-commons-delta-to-sqs" {
  depends_on = [aws_iam_policy.iam_access_s3]
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  tags                = local.resource_tags
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "era-commons-delta-to-sqs"
  file-name           = abspath("../built-artifacts/lambda-delta-to-sqs/out/lambda-delta-to-sqs.zip")
  lambda-description  = "Lambda function to send updated records from S3 bucket into SQS"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    ERA_COMMONS_SQS_URL  = "https://sqs.us-east-1.amazonaws.com/${data.aws_caller_identity._.account_id}/edis-era-commons-delta-queue-${var.env}"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_delta-to-sqs_role_policies: idx => val }
  lambda_timeout = 900
}

module "lambda-era-commons-sqs-delta-to-db" {
  source              = "../tf-lib/modules/lambda"
  env                 = var.env
  must-be-role-prefix = local.power-user-prefix
  must-be-policy-arn  = local.policy-boundary-arn
  tags                 = local.resource_tags
  region               = "us-east-1"
  app                  = "edis"
  lambda-name          = "era-commons-sqs-delta-to-db"
  file-name           = abspath("../built-artifacts/lambda-sqs-batch-to-db/out/lambda-sqs-delta-to-db.zip")
  lambda-description   = "Lambda function to receive updated eRA Commons user records from SQS and load into DynamoDB"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    TABLE     = module.ddb-era-commons.ddb-table-name
    TABLE_KEY = "USER_ID"
    SQS_URL     = "https://sqs.us-east-1.amazonaws.com/${data.aws_caller_identity._.account_id}/edis-era-commons-delta-queue-${var.env}"
    PURGE_DELETED = "false"
  })
  lambda-managed-policies = {for idx, val in local.lambda_sqs-delta-to-db_role_policies : idx => val}
  lambda_timeout          = 900
}

#
# SQS for eRA Commons records
#
resource "aws_sqs_queue" "edis-era-commons-sqs" {
  name                       = "edis-era-commons-delta-queue-${var.env}"
  visibility_timeout_seconds = 7200
  max_message_size           = 262144
  tags                       = local.resource_tags
}

#
# Policy fot SQS for eRA Commons records
#
resource "aws_sqs_queue_policy" "edis-era-commons-sqs" {
  queue_url = aws_sqs_queue.edis-era-commons-sqs.id
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
      "Resource": "${aws_sqs_queue.edis-era-commons-sqs.arn}"
    },
    {
      "Sid": "__sender_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${module.lambda-era-commons-delta-to-sqs.lambda_role_arn}"
      },
      "Action": "SQS:SendMessage",
      "Resource": "${aws_sqs_queue.edis-era-commons-sqs.arn}"
    },
    {
      "Sid": "__receiver_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${module.lambda-era-commons-sqs-delta-to-db.lambda_role_arn}"
      },
      "Action": [
        "SQS:ChangeMessageVisibility",
        "SQS:DeleteMessage",
        "SQS:ReceiveMessage"
      ],
      "Resource": "${aws_sqs_queue.edis-era-commons-sqs.arn}"
    }
  ]
}
EOF
}

#
# Event Mapping from SQS for eRA Commons records to
# corresponding lambda function
#
resource "aws_lambda_event_source_mapping" "edis-era-commons-sqs" {
  batch_size = 2
  event_source_arn = aws_sqs_queue.edis-era-commons-sqs.arn
  enabled = true
  function_name = module.lambda-era-commons-sqs-delta-to-db.arn
}

resource "aws_athena_database" "edis-athena" {
  bucket = var.s3bucket-for-era-commons-users
  name   = "era_commons_db_${var.env}"
}

#
# Athena "era_commons_prev_t" table for previous eRA Commons records
#
resource "aws_glue_catalog_table" "edis-athena-era-commons-prev" {
  database_name = aws_athena_database.edis-athena.name
  name          = "era_commons_prev_t"
  table_type = "EXTERNAL_TABLE"
  parameters = {
    EXTERNAL = "TRUE"
  }
  storage_descriptor {
    location = "s3://${var.s3bucket-for-era-commons-users}/app-edis-data-${var.env}/era-commons/prev/"
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
      name = "LOGINGOV_USER_ID"
      type = "string"
    }
    columns {
      name = "content"
      type = "string"
    }
  }
}

#
# Athena "era_commons_current_t" table for current eRA Commons records
#
resource "aws_glue_catalog_table" "edis-athena-era-commons-current" {
  database_name = aws_athena_database.edis-athena.name
  name          = "era_commons_current_t"
  table_type = "EXTERNAL_TABLE"
  parameters = {
    EXTERNAL = "TRUE"
  }
  storage_descriptor {
    location = "s3://${var.s3bucket-for-era-commons-users}/app-edis-data-${var.env}/era-commons/current/"
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
      name = "LOGINGOV_USER_ID"
      type = "string"
    }
    columns {
      name = "content"
      type = "string"
    }
  }
}


