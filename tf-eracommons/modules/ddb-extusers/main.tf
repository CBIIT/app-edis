
resource "aws_dynamodb_table" "table" {
  name           = "${var.table_name}-${var.env}"
  hash_key       = "USER_ID"
  billing_mode   = "PAY_PER_REQUEST"


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
  }

  global_secondary_index {
    hash_key        = "LOGINGOV_USER_ID"
    range_key       = "USER_ID"
    name            = "logingovIndex"
    projection_type = "ALL"
  }
}

output "ddb-table-arn" {
  value = aws_dynamodb_table.table.arn
}

output "ddb-table-name" {
  value = aws_dynamodb_table.table.name
}

output "iam-access-ddb-role-arn" {
  value = aws_iam_role.iam_access_ddb.arn
}

output "iam-access-ddb-policy-arn" {
  value = aws_iam_policy.iam_access_ddb.arn
}