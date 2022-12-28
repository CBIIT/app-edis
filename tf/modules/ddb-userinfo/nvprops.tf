
resource "aws_dynamodb_table" "nvprops_table" {
  name           = "nvprops-${var.env}"
  hash_key       = "ACCESS_KEY"
  billing_mode   = "PAY_PER_REQUEST"


  attribute {
    name = "ACCESS_KEY"
    type = "S"
  }
  attribute {
    name = "CURR_NED_ID"
    type = "S"
  }

  global_secondary_index {
    hash_key        = "CURR_NED_ID"
    range_key       = "ACCESS_KEY"
    name            = "nedidIndex"
    projection_type = "ALL"
  }

  lifecycle {
    ignore_changes = [read_capacity, write_capacity]
  }
}

output "nv-props-ddb-arn" {
  value = aws_dynamodb_table.nvprops_table.arn
}

output "nv-props-ddb-name" {
  value = aws_dynamodb_table.nvprops_table.name
}

output "iam-access-nv-props-ddb-role-arn" {
  value = aws_iam_role.iam_access_nvprops_ddb.arn
}