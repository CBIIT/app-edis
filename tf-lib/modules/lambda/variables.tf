
#---------------------------------------
# General: required
#---------------------------------------

variable "env" {
  description = "Deployment tier (dev/test/qa/stage/prod/etc.)"
}
variable "must-be-role-prefix" {
  description = "Mandatory IAM role name prefix"
}
variable "must-be-policy-arn" {
  description = "Mandatory policy to be included in any IAM role"
}
variable "region" {
  description = "AWS region"
}
variable "tags" {
  type = map
  description = "Map of NCI CBIIT mandatory tags"
}

#---------------------------------------
# Lambda: required
#---------------------------------------

variable "app" {
  description = "Name of the application"
}

variable "lambda-name" {
  description = "Partial name of the Lambda function - the full name consists of app, lambda-name, and env strings separated by '-'"
}

variable "file-name" {
  description = "Name of the zip file with lambda function body"
}

#---------------------------------------
# Lambda: optional
#---------------------------------------

variable "lambda-description" {
  description = "Lambda function description"
  default     = ""
}

variable "max-retry" {
  description = "Maxumim retry attempts"
  type        = number
  default     = 0
}

variable "lambda-env-variables" {
  description = "List of environment variables for lambda function"
  type        = map(string)
  default     = {}
}

variable "lambda-managed-policies" {
  description = "List of AWS or customer managed policies to attach to lambda iam role"
  type        = map(string)
  default     = {
    "1" = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  }
}

variable "lambda-layers" {
  description = "List of lambda layers to attach to lambda"
  type        = list(string)
  default     = null
}

variable "security_group_ids" {
  description = "List of EC2 security groups ids for Lambda function inside VPC"
  type = list(string)
  default = []
}
variable "subnet_ids" {
  description = "List of EC2 subnet ids for Lambda function inside VPC"
  type = list(string)
  default = []
}

variable "lambda_timeout" {
  description = "Lambda function timeout (default 30 sec, max is 900 - 15min)"
  type = number
  default = 30
}

# -----------------------------------------------------------------------------
# Variables: API Gateway integration
# -----------------------------------------------------------------------------
variable "create_api_gateway_integration" {
  description = "If we integrate with API Gateway, enable this. Default disabled"
  type        = bool
  default     = false
}

variable "api_gateway_rest_api_id" {
  description = "API Gateway REST API identifier, default null"
  type        = string
  default     = null
}

variable "log-retention-in-days" {
  description = "Number of days you want to retain log events, 0 means never expire.  Default is 120 days"
  default = "120"
}
