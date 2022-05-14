output "ddb-extusers-arn" {
  value = aws_dynamodb_table.dynamodb.arn
}

output "ddb-extusers-name" {
  value = aws_dynamodb_table.dynamodb.name
}

output "iam-access-ddb-role-arn" {
  value = aws_iam_role.iam_access_ddb.arn
}