resource "aws_sfn_state_machine" "edis_sfn_refresh_fred_props" {
  name       = "edis-refresh-fred_props-${var.env}"
  role_arn   = aws_iam_role.step_function.arn
  tags       = local.resource_tags
  definition = <<EOF
  {
  "Comment": "State Machine to retrieve data from Frederick Properties",
  "StartAt": "Cleanup temporary folder",
  "States": {
    "Cleanup temporary folder": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-prepare-s3-for-fred-props.arn}:$LATEST",
        "Payload": {
          "src": "fred-props/prev_tmp"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Save previous folder to temporary"
    },
    "Save previous folder to temporary": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-prepare-s3-for-fred-props.arn}:$LATEST",
        "Payload": {
          "src": "fred-props/prev",
          "dst": "fred-props/prev_tmp"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 1,
          "BackoffRate": 2
        }
      ],
      "Next": "Save current folder to previous"
    },
    "Save current folder to previous": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "Payload": {
          "src": "fred-props/current",
          "dst": "fred-props/prev"
        },
        "FunctionName": "${module.lambda-prepare-s3-for-fred-props.arn}:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Load properties data from Frederick properties"
    },
    "Load properties data from Frederick properties": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-load-from-fred-props.arn}:$LATEST"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 1,
          "BackoffRate": 2
        }
      ],
      "Next": "Calculate deltas with Athena",
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Comment": "Load properties data from Frederick Properties failed",
          "Next": "Clean up current folder"
        }
      ]
    },
    "Calculate deltas with Athena": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-fred-props-delta.arn}:$LATEST",
        "Payload": {
          "DB_NAME": "fred_props_db_${var.env}",
          "S3SUBFOLDER": "fred-props",
          "DB_CURRENT_T": "fred_props_current_t",
          "DB_PREV_T": "fred_props_prev_t"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Delta to SQS for DDB"
    },
    "Delta to SQS for DDB": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-fred-props-delta-to-sqs.arn}:$LATEST",
        "Payload": {
          "delta.$": "$.delta",
          "deleted.$": "$.deleted",
          "sqs_url_key": "FRED_PROPS_SQS_URL"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "End": true
    },
    "Clean up current folder": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-prepare-s3-for-fred-props.arn}:$LATEST",
        "Payload": {
          "src": "fred-props/current"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Restore Current Folder"
    },
    "Restore Current Folder": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-prepare-s3-for-fred-props.arn}:$LATEST",
        "Payload": {
          "src": "fred-props/prev",
          "dst": "fred-props/current"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 1,
          "BackoffRate": 2
        }
      ],
      "Next": "Restore previous folder"
    },
    "Restore previous folder": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-prepare-s3-for-fred-props.arn}:$LATEST",
        "Payload": {
          "src": "fred-props/prev_tmp",
          "dst": "fred-props/prev"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Fail"
    },
    "Fail": {
      "Type": "Fail",
      "Cause": "Frederick propertiess load failed"
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_rule" "edis_refresh_fred_props" {
  name = "edis-fred_props-refresh-${var.env}"
  description = "Start Step Function to refresh Frederick Properties data"
  schedule_expression = lookup(local.tier_conf, var.env).step_fred_props_cron
  tags                = local.resource_tags
}

resource "aws_cloudwatch_event_target" "edis_refresh_fred_props" {
  arn  = aws_sfn_state_machine.edis_sfn_refresh_fred_props.arn
  rule = aws_cloudwatch_event_rule.edis_refresh_fred_props.name
  role_arn = aws_iam_role.refresh_fred_props_trigger.arn
}