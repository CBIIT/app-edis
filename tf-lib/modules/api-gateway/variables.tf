
#---------------------------------------
# General: required
#---------------------------------------
variable "env" {
  description = "The deployment tier (dev/test/qa/stage/prod and others)"
}
variable "must-be-role-prefix" {
  description = "Mandatory IAM role name prefix"
}
variable "must-be-policy-arn" {
  description = "Mandatory policy to be included in any IAM role"
}
variable "tags" {
  type = map
  description = "Map of NCI CBIIT mandatory tags"
}

#---------------------------------------
# API Gateway: required
#---------------------------------------

variable "app" {
  description = "Name of the project that will be assigned as a tag to every resource of the project, also used in API Gateway API name"
}

variable "api-gateway-name" {
  description = "Partial name of the API Gateway - the full name also includes app and env values"
}

variable "api-swagger" {
  description = "The rendered OpenAPI specification that defines the set of routes and integrations to create as part of the REST API."
}

#---------------------------------------
# API Gateway: optional
#---------------------------------------

variable "app-description" {
  default     = ""
  description = "Description of API Gateway project"
}

variable "api-resource-policy" {
  default     = ""
  description = "Optional resource policy to be applied to api gateway"
}

variable "lambda-log-level" {
  type        = string
  description = "LOG LEVEL of lambda authorizer"
  default     = "INFO"
}

variable "cache_enabled" {
  type = bool
  description = "Set to true to enable API Gateway cache"
  default = false
}

variable "cache_size" {
  type = string
  description = "Size of API Gateway cache (not applied if cache_enabled is false)"
  default = "1.6"
}

variable "trace_enabled" {
  type = bool
  description = "Set to true to enable API Gateway tracing"
  default = false
}

