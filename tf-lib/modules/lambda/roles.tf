
data "aws_iam_policy_document" "assume_role_lambda_service" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name                 = "${var.must-be-role-prefix}-lambda-${var.lambda-name}-${var.env}"
  assume_role_policy   = data.aws_iam_policy_document.assume_role_lambda_service.json
  path                 = "/"
  permissions_boundary = var.must-be-policy-arn
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "iam_for_lambda" {
  for_each   = var.lambda-managed-policies
  policy_arn = each.value
  role       = aws_iam_role.iam_for_lambda.name
}

