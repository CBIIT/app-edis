
resource "aws_dynamodb_table" "extusers-table" {
  name = "extusers-${var.env}"
  hash_key = "USER_ID"
  billing_mode = "PROVISIONED"
  read_capacity = 5
  write_capacity = 5
  
  
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
    read_capacity = 5
    write_capacity = 5
  }

  global_secondary_index {
    hash_key        = "LOGINGOV_USER_ID"
    range_key       = "USER_ID"
    name            = "logingovIndex"
    projection_type = "ALL"
    read_capacity = 5
    write_capacity = 5
  }
}

output "ddb-extusers-arn" {
  value = aws_dynamodb_table.extusers-table.arn
}

output "ddb-extusers-name" {
  value = aws_dynamodb_table.extusers-table.name
}

output "iam-access-ddb-role-arn" {
  value = aws_iam_role.iam_access_ddb.arn
}