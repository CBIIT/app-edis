variable "role-prefix" {
  type = string
  description = "Must be prefix to any IAM role"
  default = "power-user"
}

variable "policy-boundary-arn" {
  type = string
  description = "Must be policy to include in any IAM role"
  default = ""
}

variable "env" {
  type = string
  default = "dev"
  description = "Environment tier"
}

