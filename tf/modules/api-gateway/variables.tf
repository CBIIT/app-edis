variable "env" {
  default = ""
  description = "The deployment tier (dev/test/qa/stage/prod and others)"
}
variable "must-be-role-prefix" {
  default = ""
  description = "Mandatory IAM role name prefix"
}
variable "must-be-policy-arn" {
  default = ""
  description = "Mandatory policy to be included in any IAM role"
}

variable "okta-issuer" {
  default = ""
  description = "URL to OKTA provider authentication server"
}

variable "okta-audience" {
  default = "api://default"
  description = "AUDIENCE for OKTA provider authentication server"
}

variable "app-name" {
  default = "apigateway"
  description = "Name of the project that will be assigned as a tag to every resource of the project, also used in API Gateway API name" 
}

variable "app-description" {
  default = ""
  description = "Description of API Gateway project" 
}

variable "api-swagger" {
  default = ""
  description = "The rendered OpenAPI specification that defines the set of routes and integrations to create as part of the REST API."
}

variable "api-resource-policy" {
  default = ""
  description = "Optional resource policy to be applied to api gateway"
}
