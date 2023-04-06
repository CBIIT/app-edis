
output "name" {
  value = aws_lambda_function.lambda.function_name
}

output "arn" {
  value = aws_lambda_function.lambda.arn
}

output "invoke_arn" {
  value = aws_lambda_function.lambda.invoke_arn
}

output "lambda_role_arn" {
  value = aws_iam_role.iam_for_lambda.arn
}
