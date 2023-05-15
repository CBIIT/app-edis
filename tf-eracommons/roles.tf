data "aws_iam_policy_document" "iam_access_s3" {
  statement {
    sid     = "s3VdsPermissions"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.s3bucket-for-era-commons-users}/app-edis-data-${var.env}/*"
    ]
  }
  statement {
    sid     = "s3ListeRACommonsFiles"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.s3bucket-for-era-commons-users}"
    ]
    condition {
      test     = "StringLike"
      values   = [ "app-edis-data-${var.env}/*" ]
      variable = "s3:prefix"
    }
  }
}

resource "aws_iam_policy" "iam_access_s3" {
  name        = "${local.power-user-prefix}-s3-edis-era-commons-data-${var.env}"
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
  name               = "${local.power-user-prefix}-step-function-era-commons-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_step_function.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaRole",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
  path                 = "/"
  permissions_boundary = local.policy-boundary-arn
}

