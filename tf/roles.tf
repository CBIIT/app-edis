data "aws_iam_policy_document" "iam_access_s3" {
  statement {
    sid     = "s3VdsPermissions"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.s3bucket-for-vds-users}/app-edis-data-${var.env}/*"
    ]
  }
  statement {
    sid     = "s3ListVdsFiles"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.s3bucket-for-vds-users}"
    ]
    condition {
      test     = "StringLike"
      values   = [ "app-edis-data-${var.env}/*" ]
      variable = "s3:prefix"
    }
  }
}

resource "aws_iam_policy" "iam_access_s3" {
  name        = "${var.role-prefix}-s3-app-edis-data-${var.env}"
  path        = "/"
  description = "Access to given S3 bucket folder"
  policy      = data.aws_iam_policy_document.iam_access_s3.json
}

data "aws_iam_policy_document" "assume_role_step_function" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "step_function" {
  name               = "${var.role-prefix}-step-function-vds-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_step_function.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaRole",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
  path                 = "/"
  permissions_boundary = var.policy-boundary-arn
}

