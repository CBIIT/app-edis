variable "pspath" {
  type        = string
  default     = "/dev/app/eadis"
  description = "Parameter Store prefix path"
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
