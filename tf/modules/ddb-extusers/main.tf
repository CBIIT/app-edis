
resource "aws_dynamodb_table" "dynamodb" {
  name             = "${var.app}-dynamodb-table-${var.env}"
  hash_key         = var.dynamodb_hash_key
  billing_mode     = var.dynamodb_billing_mode
  read_capacity    = var.dynamodb_read_capacity
  write_capacity   = var.dynamodb_write_capacity
  stream_enabled   = var.dynamodb_stream_enabled
  stream_view_type = var.dynamodb_stream_view_type
  table_class      = var.dynamodb_table_class

  ttl {
    enabled        = var.dynamodb_ttl_enabled
    attribute_name = "ttl"
  }

  attribute {
    name = "USER_ID"
    type = "S"
  }
  attribute {
    name = "LAST_UPDATED_DAY"
    type = "S"
  }
  attribute {
    name = "LOGINGOV_USER_ID"
    type = "S"
  }

  global_secondary_index {
    hash_key        = "LAST_UPDATED_DAY"
    range_key       = "USER_ID"
    name            = "dateIndex"
    projection_type = "ALL"
    read_capacity   = 5
    write_capacity  = 5
  }

  global_secondary_index {
    hash_key        = "LOGINGOV_USER_ID"
    range_key       = "USER_ID"
    name            = "logingovIndex"
    projection_type = "ALL"
    read_capacity   = 5
    write_capacity  = 5
  }
}