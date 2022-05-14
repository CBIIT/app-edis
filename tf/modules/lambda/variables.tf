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
