variable "env" {
  type        = string
  default     = "dev"
  description = "Environment tier"
}

variable "parameters" {
  type = string
  description = "Stringified JSON of key-values pairs"
  default = ""
}

variable "secure_parameters" {
  type = string
  description = "Stringified JSON of key-values pairs for secure strings"
  default = ""
}
