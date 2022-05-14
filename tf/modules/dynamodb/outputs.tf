output "dynamodb_arn" {
  value = aws_dynamodb_table.dynamodb.arn
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.dynamodb.name
}