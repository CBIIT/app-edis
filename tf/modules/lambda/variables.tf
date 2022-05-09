variable "env" {
  default = ""
}
variable "must-be-role-prefix" {
  default = ""
  description = "Mandatory IAM role name prefix"
}
variable "must-be-policy-arn" {
  default = ""
  description = "Mandatory policy to be included in any IAM role"
}

variable "ddb-table-arn" {
  default = ""
  description = "Dynamo DB table ARN to connect API Gateway method to Dynamo DB"
}
