
resource "aws_dynamodb_table" "table" {
  name           = "userinfo-${var.env}"
  hash_key       = "NEDId"
  billing_mode   = "PAY_PER_REQUEST"


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
  }

  lifecycle {
    ignore_changes = [read_capacity, write_capacity]
  }
  
  tags = {
    Tier = var.env
    App = var.resource_tag_name
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