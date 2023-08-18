# Global API Gateway resource
resource "aws_iam_role" "api_gateway" {
  name               = "${local.power-user-prefix}-api-gateway-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_api_gateway_service.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
  ]
  path                 = "/"
  permissions_boundary = local.policy-boundary-arn
}

resource "aws_api_gateway_account" "api_gateway" {
  cloudwatch_role_arn = aws_iam_role.api_gateway.arn
}

# Global Lambda OracleDB Layer
resource "aws_lambda_layer_version" "oracledb" {
  layer_name = "edis-oracle-db-layer"
  s3_bucket = var.s3bucket
  s3_key = "api-edis-tf-state/oracledb-layer.zip"
  compatible_runtimes = ["nodejs10.x","nodejs12.x","nodejs14.x"]
  description = "OracleDB lambda layer to connect to Oracle database"
}


