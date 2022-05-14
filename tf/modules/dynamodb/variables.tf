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

variable "dynamodb_ttl_enabled" {
  type        = bool
  description = ""
  default     = false
}

variable "dynamodb_stream_enabled" {
  type    = bool
  default = false
}

variable "dynamodb_stream_view_type" {
  type        = string
  description = "When an item in the table is modified, StreamViewType determines what information is written to the table's stream. Valid values are KEYS_ONLY, NEW_IMAGE, OLD_IMAGE, NEW_AND_OLD_IMAGES."
}

variable "dynamodb_table_class" {
  type        = string
  description = "The storage class of the table. Valid values are STANDARD and STANDARD_INFREQUENT_ACCESS."
  default     = "STANDARD"
}

variable "must-be-role-prefix" {
  type        = string
  description = "Mandatory IAM role name prefix"
}
variable "must-be-policy-arn" {
  type        = string
  description = "Mandatory policy to be included in any IAM role"
}

