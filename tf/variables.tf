variable "role-prefix" {
  type = string
  description = "Must be prefix to any IAM role"
  default = "power-user"
}

variable "role-policy-name" {
  type = string
  description = "Must be policy to include in any IAM role"
  default = "PermissionBoundary_PowerUser"
}

variable "env" {
  type = string
  default = "dev"
  description = "Environment tier"
}

