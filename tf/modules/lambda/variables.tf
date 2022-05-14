variable "app" {
  type        = string
  description = "Provide the name of the application or the service"
}

variable "lambda_description" {
  type        = string
  description = "Provide a description for the lambda function"
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

variable "lambda_memory_size" {
  type        = number
  description = "The memory allocation for the lambda function"
  default     = 2048
}

variable "lambda_timeout" {
  type        = number
  description = "The lambda function timeout duration"
  default     = 30
}

variable "lambda_file_location" {
  type        = string
  description = "Location of the file that contains the lambda function code (i.e. '../lambda-zip/lambda-userapi/lambda-userapi.zip')"
}

variable "env" {
  type        = string
  description = "The target environment for the deployment"
}
variable "must-be-role-prefix" {
  type        = string
  description = "Mandatory IAM role name prefix"
}
variable "must-be-policy-arn" {
  default     = ""
  description = "Mandatory policy to be included in any IAM role"
}

variable "ddb-table-name" {
  type        = string
  description = "Dynamo DB table name to connect Lambda function to Dynamo DB"
}
