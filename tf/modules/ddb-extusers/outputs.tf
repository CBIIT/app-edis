output "dynamodb_arn" {
  value = aws_dynamodb_table.dynamodb.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.dynamodb.name
}

output "iam_dynamodb_access_role_arn" {
  value = aws_iam_role.iam_access_ddb.arn
}