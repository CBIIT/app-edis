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

variable "email" {
  type = string
  description = "Email of the user that triggered run"
  default = ""
}