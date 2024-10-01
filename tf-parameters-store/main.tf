
resource "aws_ssm_parameter" "eadis" {
  for_each = local.parameter_pairs
  name  = "/${var.pspath}${each.key}"
  type  = "String"
  value = each.value
  overwrite = true
}

resource "aws_ssm_parameter" "secure_eadis" {
  for_each = local.secure_parameter_pairs
  name  = "${var.pspath}${each.key}"
  type  = "SecureString"
  value = each.value
  overwrite = true
}
