variable "env" {
  default = ""
}

variable "must-be-role-prefix" {
  default     = ""
  description = "Mandatory IAM role name prefix"
}
variable "must-be-policy-arn" {
  default     = ""
  description = "Mandatory boundary policy to be included in any IAM role"
}
