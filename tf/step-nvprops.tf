resource "aws_sfn_state_machine" "edis_sfn_refresh_nv_props" {
  count = (var.build-userinfo) ? 1 : 0
  name       = "edis-refresh-nv-props-${var.env}"
  role_arn   = aws_iam_role.step_function[0].arn
  definition = <<EOF
  {
  "Comment": "State Machine to retrieve properties data from nVision",
  "StartAt": "Cleanup temporary folder",
  "States": {
    "Cleanup temporary folder": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-prepare-s3-for-vds[0].arn}:$LATEST",
        "Payload": {
          "src": "nv-props/prev_tmp"
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
        "FunctionName": "${module.lambda-prepare-s3-for-vds[0].arn}:$LATEST",
        "Payload": {
          "src": "nv-props/prev",
          "dst": "nv-props/prev_tmp"
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
        "FunctionName": "${module.lambda-prepare-s3-for-vds[0].arn}:$LATEST"
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
      "Next": "Load properties data from nVision"
    },
    "Load properties data from nVision": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-load-from-nv-props[0].arn}:$LATEST" 
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
          "Comment": "Load properties data from nVision failed",
          "Next": "Clean up current folder"
        }
      ]
    },
    "Calculate deltas with Athena": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-vds-users-delta[0].arn}:$LATEST"
        "Payload": {
          "DB_NAME": "vdsdb_dev",
          "S3SUBFOLDER": "nv-props",
          "DB_CURRENT_T": "nvprops-current_t",
          "DB_PREV_T": "nvprops_prev_t"
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
        "FunctionName": "${module.lambda-delta-to-sqs[0].arn}:$LATEST",
        "Payload": {
          "delta.$": "$.delta",
          "deleted.$": "$.deleted",
          "sqs_url_key": "NVPROPS_SQS_URL"
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
        "FunctionName": "${module.lambda-prepare-s3-for-vds[0].arn}:$LATEST",
        "Payload": {
          "src": "nv-props/current"
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
        "FunctionName": "${module.lambda-prepare-s3-for-vds[0].arn}:$LATEST",
        "Payload": {
          "src": "nv-props/prev",
          "dst": "nv-props/current"
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
        "FunctionName": "${module.lambda-prepare-s3-for-vds[0].arn}:$LATEST",
        "Payload": {
          "src": "nv-props/prev_tmp",
          "dst": "nv-props/prev"
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
      "Cause": "nVision load failed"
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_rule" "edis_refresh_nv_props" {
  count = (var.build-userinfo) ? 1 : 0
  name = "edis-nv-props-refresh-${var.env}"
  description = "Start Step Function to refresh nVision properties data"
  schedule_expression = lookup(local.tier_conf, var.env).step_nv_props_cron
}

resource "aws_cloudwatch_event_target" "edis_refresh_nv_props" {
  count = (var.build-userinfo) ? 1 : 0
  arn  = aws_sfn_state_machine.edis_sfn_refresh_nv_props[0].arn
  rule = aws_cloudwatch_event_rule.edis_refresh_nv_props[0].name
  role_arn = aws_iam_role.refresh_vds_trigger[0].arn
}