
resource "aws_dynamodb_table" "table" {
  name           = "${var.table_name}-${var.env}"
  hash_key       = "PropertyNumber"
  billing_mode   = "PAY_PER_REQUEST"


  attribute {
    name = "PropertyNumber"
    type = "S"
  }
  attribute {
    name = "PropertyOfficerNedId"
    type = "S"
  }
  attribute {
    name = "CustodianNedId"
    type = "S"
  }

  global_secondary_index {
    hash_key        = "PropertyOfficerNedId"
    range_key       = "PropertyNumber"
    name            = "officerIndex"
    projection_type = "ALL"
  }

  global_secondary_index {
    hash_key        = "CustodianNedId"
    range_key       = "PropertyNumber"
    name            = "custodianIndex"
    projection_type = "ALL"
  }

  tags = var.tags
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