data "aws_iam_policy_document" "dynamodb_assume_role" {
  statement {
    sid     = "DynamoAssumeRoleAPIGW"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    sid    = "DynamoDbAccess"
    effect = "Allow"
    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:ConditionCheckItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:GetItem",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams",
      "dynamodb:ListTables",
      "dynamodb:ListTagsOfResource",
      "dynamodb:PartiQLDelete",
      "dynamodb:PartiQLInsert",
      "dynamodb:PartiQLSelect",
      "dynamodb:PartiQLUpdate",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
      "dynamodb:UpdateItem",
      "dynamodb:UpdateTable",
      "dynamodb:UpdateTimeToLive"
    ]
    resources = [
      aws_dynamodb_table.dynamodb.arn,
      "${aws_dynamodb_table.dynamodb.arn}/index/*",
      "${aws_dynamodb_table.dynamodb.arn}/stream/*"
    ]
  }
}


policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Action = ["dynamodb:*"]
      Effect = "Allow"
      Sid    = "ddbPermissions"
      Resource = [
        aws_dynamodb_table.dynamodb.arn,
        "${aws_dynamodb_table.dynamodb.arn}/index/*"
      ]
    }
  ]
})