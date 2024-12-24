data "aws_iam_policy_document" "iam_access_s3" {
  statement {
    sid     = "s3VdsPermissions"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      "arn:aws:s3:::${var.s3bucket-for-fred-props}/app-edis-data-${var.env}/*"
    ]
  }
  statement {
    sid     = "s3ListFredPropsFiles"
    effect  = "Allow"
    actions = ["s3:ListBucket"]
    resources = [
      "arn:aws:s3:::${var.s3bucket-for-fred-props}"
    ]
    condition {
      test     = "StringLike"
      values   = [ "app-edis-data-${var.env}/*" ]
      variable = "s3:prefix"
    }
  }
}

resource "aws_iam_policy" "iam_access_s3" {
  name        = "${local.power-user-prefix}-s3-edis-fred-props-data-${var.env}"
  path        = "/"
  description = "Access to given S3 bucket folder"
  policy      = data.aws_iam_policy_document.iam_access_s3.json
  tags        = local.resource_tags
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
  name               = "${local.power-user-prefix}-step-function-fred-props-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_step_function.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaRole",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
  path                 = "/"
  permissions_boundary = local.policy-boundary-arn
  tags                 = local.resource_tags
}

data "aws_iam_policy_document" "assume_role_event_trigger" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "iam_refresh_fred_props" {
  statement {
    sid     = "executeStep"
    effect  = "Allow"
    actions = ["states:StartExecution"]
    resources = [
      aws_sfn_state_machine.edis_sfn_refresh_fred_props.arn
    ]
  }
}

resource "aws_iam_policy" "iam_refresh_fred_props" {
  name        = "${local.power-user-prefix}-start-fred-props-refresh-${var.env}"
  path        = "/"
  description = "Allow trigger event to start refresh the Frederick Property data"
  policy      = data.aws_iam_policy_document.iam_refresh_fred_props.json
  tags        = local.resource_tags
}

resource "aws_iam_role" "refresh_fred_props_trigger" {
  name               = "${local.power-user-prefix}-start-fred-props-refresh-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_event_trigger.json
  managed_policy_arns = [
    aws_iam_policy.iam_refresh_fred_props.arn
  ]
  path                 = "/"
  permissions_boundary = local.policy-boundary-arn
  tags                 = local.resource_tags
}

