#
# Lambda - Load properties records from nVision into S3 bucket storage.parquet file
#
module "lambda-load-from-nv-props" {
  count = (var.build-userinfo) ? 1 : 0
  source              = "./modules/lambda"
  depends_on = [aws_iam_policy.iam_access_s3]
  env                 = var.env
  must-be-role-prefix = var.role-prefix
  must-be-policy-arn  = var.policy-boundary-arn
  resource_tag_name   = "edis"
  region              = "us-east-1"
  app                 = "edis"
  lambda-name         = "load-from-nv-props"
  file-name           = "../lambda-zip/lambda-load-from-nv-props.zip"
  lambda-description  = "Lambda function to load nVision properties into S3 bucket"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    SECRET    = lookup(local.tier_conf, var.env).secret
    S3BUCKET  = var.s3bucket-for-vds-users
    S3FOLDER  = "app-edis-data-${var.env}/nv-props/current"
    S3FILE  = "storage.parquet"
  })
  lambda-managed-policies        = { for idx, val in local.lambda_load_from_vds_role_policies: idx => val }
  lambda-layers = local.lambda-eracommons-layers
  subnet_ids = [ var.subnet1, var.subnet2 ]
  security_group_ids = [ var.vpcsg ]
  lambda_timeout = 900
  max-retry = 1
}

#
# Lambda - Update nVision Properties Dynamo DB with update/delete records from SQS
#
module "lambda-nv-props-sqs-delta-to-db" {
  count = (var.build-userinfo) ? 1 : 0
  source               = "./modules/lambda"
  env                  = var.env
  must-be-role-prefix  = var.role-prefix
  must-be-policy-arn   = var.policy-boundary-arn
  resource_tag_name    = "edis"
  region               = "us-east-1"
  app                  = "edis"
  lambda-name          = "nv-props-sqs-delta-to-db"
  file-name            = "../lambda-zip/lambda-sqs-delta-to-db.zip"
  lambda-description   = "Lambda function to receive updated nVision properties records from SQS and load into DynamoDB"
  lambda-env-variables = tomap({
    LOG_LEVEL = "info"
    TABLE     = module.ddb-userinfo[0].nv-props-ddb-name
    TABLE_KEY = "ASSET_KEY"
    SQS_URL     = "https://sqs.us-east-1.amazonaws.com/${data.aws_caller_identity._.account_id}/edis-nv-props-delta-queue-${var.env}"
    PURGE_DELETED = "true"
  })
  lambda-managed-policies = {for idx, val in local.lambda_sqs-delta-to-db_role_policies : idx => val}
  lambda_timeout          = 900
}

#
# SQS for nVision properties records
#
resource "aws_sqs_queue" "edis-nv-props-sqs" {
  count                      = (var.build-userinfo) ? 1 : 0
  name                       = "edis-nv-props-delta-queue-${var.env}"
  visibility_timeout_seconds = 7200
  max_message_size           = 262144
}

#
# Policy fot SQS for nVision properties records
#
resource "aws_sqs_queue_policy" "edis-nv-props-sqs" {
  count     = (var.build-userinfo) ? 1 : 0
  queue_url = aws_sqs_queue.edis-nv-props-sqs[0].id
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
      "Resource": "${aws_sqs_queue.edis-nv-props-sqs[0].arn}"
    },
    {
      "Sid": "__sender_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${module.lambda-delta-to-sqs[0].lambda_role_arn}"
      },
      "Action": "SQS:SendMessage",
      "Resource": "${aws_sqs_queue.edis-nv-props-sqs[0].arn}"
    },
    {
      "Sid": "__receiver_statement",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${module.lambda-nv-props-sqs-delta-to-db[0].lambda_role_arn}"
      },
      "Action": [
        "SQS:ChangeMessageVisibility",
        "SQS:DeleteMessage",
        "SQS:ReceiveMessage"
      ],
      "Resource": "${aws_sqs_queue.edis-nv-props-sqs[0].arn}"
    }
  ]
}
EOF
}

#
# Event Mapping from SQS for nVision properties records to
# corresponding lambda function
#
resource "aws_lambda_event_source_mapping" "edis-nv-props-sqs" {
  count = (var.build-userinfo) ? 1 : 0
  batch_size = 2
  event_source_arn = aws_sqs_queue.edis-nv-props-sqs[0].arn
  enabled = true
  function_name = module.lambda-nv-props-sqs-delta-to-db[0].arn
}

#
# Athena "nvprops_prev_t" table for previous nVision properties records
#
resource "aws_glue_catalog_table" "edis-athena-nvprops-prev" {
  count = (var.build-userinfo) ? 1 : 0
  database_name = aws_athena_database.edis-athena[0].name
  name          = "nvprops_prev_t"
  table_type = "EXTERNAL_TABLE"
  parameters = {
    EXTERNAL = "TRUE"
  }
  storage_descriptor {
    location = "s3://${var.s3bucket-for-vds-users}/app-edis-data-${var.env}/nv-props/prev/"
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
      name = "content"
      type = "string"
    }
  }
}

#
# Athena "nvprops_current_t" table for current nVision properties records
#
resource "aws_glue_catalog_table" "edis-athena-nvprops-current" {
  count = (var.build-userinfo) ? 1 : 0
  database_name = aws_athena_database.edis-athena[0].name
  name          = "nvprops_current_t"
  table_type = "EXTERNAL_TABLE"
  parameters = {
    EXTERNAL = "TRUE"
  }
  storage_descriptor {
    location = "s3://${var.s3bucket-for-vds-users}/app-edis-data-${var.env}/nv-props/current/"
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
      name = "content"
      type = "string"
    }
  }
}

