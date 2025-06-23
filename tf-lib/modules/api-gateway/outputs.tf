
output "rest_api_id" {
  value = aws_api_gateway_rest_api.api_gateway.id
}

output "root_resource_id" {
  value = aws_api_gateway_rest_api.api_gateway.root_resource_id
}