variable "role-prefix" {
  type        = string
  description = "Must be prefix to any IAM role"
  default     = "power-user-edis"
}

variable "policy-boundary-arn" {
  type        = string
  description = "Must be policy to include in any IAM role"
  default     = ""
}

variable "env" {
  type        = string
  default     = "dev"
  description = "Environment tier"
}

variable "subnet1" {
  type = string
  description = "VPC Subnet 1 id for Lambda functions placed inside VPC"
}

variable "subnet2" {
  type = string
  description = "VPC Subnet 2 id for Lambda functions placed inside VPC"
}

variable "vpcsg" {
  type = string
  description = "Security Group id for Lambda functions placed inside VPC"
}

variable "build-eracommons" {
  type = bool
  description = "Set to true to deploy era commons API related resources"
  default = false
}

variable "build-userinfo" {
  type = bool
  description = "Set to true to deploy user info API related resources"
  default = false
}

variable "s3bucket-for-vds-users" {
  type = string
  description = "S3 Bucket name to load users info from VDS"
}

variable "oracle-db-layer-arn" {
  type = string
  description = "ARN of the latest version of oracle db lambda layer"
  default = null
}