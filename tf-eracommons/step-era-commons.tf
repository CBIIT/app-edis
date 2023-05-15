resource "aws_sfn_state_machine" "edis_sfn_refresh_era_commons" {
  name       = "edis-refresh-era-commons-${var.env}"
  role_arn   = aws_iam_role.step_function.arn
  definition = <<EOF
  {
  "Comment": "State Machine to retrieve data from eRA Commons",
  "StartAt": "Cleanup temporary folder",
  "States": {
    "Cleanup temporary folder": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-prepare-s3-for-era-commons.arn}:$LATEST",
        "Payload": {
          "src": "era-commons/prev_tmp"
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
        "FunctionName": "${module.lambda-prepare-s3-for-era-commons.arn}:$LATEST",
        "Payload": {
          "src": "era-commons/prev",
          "dst": "era-commons/prev_tmp"
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
          "src": "nv-props/current",
          "dst": "nv-props/prev"
        },
        "FunctionName": "${module.lambda-prepare-s3-for-era-commons.arn}:$LATEST"
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
      "Next": "Load properties data from eRA Commons"
    },
    "Load properties data from nVision": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-load-from-era-commons.arn}:$LATEST"
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
          "Comment": "Load properties data from eRA Commons failed",
          "Next": "Clean up current folder"
        }
      ]
    },
    "Calculate deltas with Athena": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-era-commons-delta.arn}:$LATEST",
        "Payload": {
          "DB_NAME": "era_commons_db_${var.env}",
          "S3SUBFOLDER": "era-commons",
          "DB_CURRENT_T": "era_commons_current_t",
          "DB_PREV_T": "era_commons_prev_t"
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
        "FunctionName": "${module.lambda-era-commons-delta-to-sqs.arn}:$LATEST",
        "Payload": {
          "delta.$": "$.delta",
          "deleted.$": "$.deleted",
          "sqs_url_key": "ERA_COMMONS_SQS_URL"
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
        "FunctionName": "${module.lambda-prepare-s3-for-era-commons.arn}:$LATEST",
        "Payload": {
          "src": "era-commons/current"
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
        "FunctionName": "${module.lambda-prepare-s3-for-era-commons.arn}:$LATEST",
        "Payload": {
          "src": "era-commons/prev",
          "dst": "era-commons/current"
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
        "FunctionName": "${module.lambda-prepare-s3-for-era-commons.arn}:$LATEST",
        "Payload": {
          "src": "era-commons/prev_tmp",
          "dst": "era-commons/prev"
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
      "Cause": "era Commons load failed"
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_rule" "edis_refresh_era_commons" {
  name = "edis-era-commons-refresh-${var.env}"
  description = "Start Step Function to refresh eRA Commons data"
  schedule_expression = lookup(local.tier_conf, var.env).step_era_commons_cron
}

resource "aws_cloudwatch_event_target" "edis_refresh_era_commons" {
  arn  = aws_sfn_state_machine.edis_sfn_refresh_era_commons.arn
  rule = aws_cloudwatch_event_rule.edis_refresh_era_commons.name
  role_arn = aws_iam_role.refresh_era_commons_trigger.arn
}