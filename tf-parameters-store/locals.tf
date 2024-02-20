locals {
  parameter_pairs = var.parameters == "" ? {} : jsondecode(var.parameters)
  secure_parameter_pairs = var.secure_parameters == "" ? {} : jsondecode(var.secure_parameters)
}