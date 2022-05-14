variable "app" {
  type        = string
  description = ""
}

variable "env" {
  description = "The deployment tier (dev/test/qa/stage/prod and others)"
}
variable "must-be-role-prefix" {
  default     = ""
  description = "Mandatory IAM role name prefix"
}
variable "must-be-policy-arn" {
  default     = ""
  description = "Mandatory policy to be included in any IAM role"
}

variable "okta-issuer" {
  default     = ""
  description = "URL to OKTA provider authentication server"
}

variable "okta-audience" {
  default     = "api://default"
  description = "AUDIENCE for OKTA provider authentication server"
}

variable "lambda_log_level" {
  type        = string
  description = "Set the log level for your Lambda Function"
  default     = "info"
}

variable "app-name" {
  default     = "apigateway"
  description = "Name of the project that will be assigned as a tag to every resource of the project, also used in API Gateway API name"
}

variable "lambda_handler_file" {
  type        = string
  description = "The source location for the lambda handler definition (i.e. src/handler.lambda)"
}

variable "lambda_runtime" {
  type        = string
  description = "The runtime for the lambda function. The default value represents the latest runtime version validated for this configuration"
  default     = "nodejs12.x"
}

variable "app-description" {
  default     = ""
  description = "Description of API Gateway project"
}

variable "api-swagger" {
  default     = ""
  description = "The rendered OpenAPI specification that defines the set of routes and integrations to create as part of the REST API."
}

variable "lambda_config_retry_attempts" {
  type        = number
  description = "Maximum number of times to retry when the function returns an error. Valid values between 0 and 2."
  default     = 0
}

variable "api-resource-policy" {
  default     = ""
  description = "Optional resource policy to be applied to api gateway"
}

variable "lambda_file_location" {
  type        = string
  description = "Path to the function's deployment package within the local filesystem (i.e. '../lambda-zip/lambda-userapi/lambda-userapi.zip')"
}
