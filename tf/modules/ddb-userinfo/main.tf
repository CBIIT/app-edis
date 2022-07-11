
resource "aws_dynamodb_table" "table" {
  name           = "userinfo-${var.env}"
  hash_key       = "NEDId"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5


  attribute {
    name = "NEDId"
    type = "S"
  }
  attribute {
    name = "NIHORGACRONYM"
    type = "S"
  }

  global_secondary_index {
    hash_key        = "NIHORGACRONYM"
    range_key       = "NEDId"
    name            = "icIndex"
    projection_type = "ALL"
    read_capacity   = 10
    write_capacity  = 10
  }

  lifecycle {
    ignore_changes = [read_capacity, write_capacity]
  }
}

output "ddb-arn" {
  value = aws_dynamodb_table.table.arn
}

output "ddb-name" {
  value = aws_dynamodb_table.table.name
}

output "iam-access-ddb-role-arn" {
  value = aws_iam_role.iam_access_ddb.arn
}