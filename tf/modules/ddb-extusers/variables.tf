variable "env" {
  type = string
}

variable "app" {
  type = string
}

variable "dynamodb_hash_key" {
  type = string
}

variable "dynamodb_billing_mode" {
  type = string
}

variable "dynamodb_read_capacity" {
  type    = number
  default = 5
}

variable "dynamodb_write_capacity" {
  type    = number
  default = 5
}

variable "must-be-role-prefix" {
  type        = string
  description = "Mandatory IAM role name prefix"
}
variable "must-be-policy-arn" {
  type        = string
  description = "Mandatory policy to be included in any IAM role"
}

