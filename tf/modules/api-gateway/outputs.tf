
output "url" {
  value = "${aws_api_gateway_deployment.api_gateway.invoke_url}/api"
}

output "rest_api_id" {
  value = aws_api_gateway_rest_api.api_gateway.id
}