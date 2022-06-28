data "aws_iam_policy_document" "iam_access_s3" {
  statement {
    sid     = "s3VdsPermissions"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.s3bucket-for-vds-users}/app-edis-data-${var.env}/*"
    ]
  }
}

resource "aws_iam_policy" "iam_access_s3" {
  name        = "${var.role-prefix}-s3-app-edis-data-${var.env}"
  path        = "/"
  description = "Access to given S3 bucket folder"
  policy      = data.aws_iam_policy_document.iam_access_s3.json
}
