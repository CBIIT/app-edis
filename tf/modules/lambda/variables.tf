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
  description = "Amount of memory allocated to your Lambda Function, used at runtime (in MB)."
  default     = 2048
}

variable "lambda_timeout" {
  type        = number
  description = "Amount of time your Lambda Function has to run (in seconds)."
  default     = 30
}

variable "lambda_file_location" {
  type        = string
  description = "Path to the function's deployment package within the local filesystem (i.e. '../lambda-zip/lambda-userapi/lambda-userapi.zip')"
}

variable "lambda_log_level" {
  type        = string
  description = "Set the log level for your Lambda Function"
  default     = "info"
}

variable "lambda_tracing_mode" {
  type        = string
  description = "Whether to to sample and trace a subset of incoming requests with AWS X-Ray. Valid values are PassThrough and Active. If PassThrough, Lambda will only trace the request from an upstream service if it contains a tracing header with 'sampled=1'. If Active, Lambda will respect any tracing header it receives from an upstream service. If no tracing header is received, Lambda will call X-Ray for a tracing decision."
}

variable "lambda_config_retry_attempts" {
  type        = number
  description = "Maximum number of times to retry when the function returns an error. Valid values between 0 and 2."
  default     = 0
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
  type        = string
  description = "Mandatory policy to be included in any IAM role"
}

variable "ddb-table-name" {
  type        = string
  description = "Dynamo DB table name to connect Lambda function to Dynamo DB"
}
