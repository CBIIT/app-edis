resource "aws_sfn_state_machine" "edis_sfn_refresh_vds" {
  name       = "edis-refresh-vds-${var.env}"
  role_arn   = aws_iam_role.step_function.arn
  definition = <<EOF
  {
  "Comment": "State Machine to retrieve user data from VDS",
  "StartAt": "Cleanup temporary folder",
  "States": {
    "Cleanup temporary folder": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-prepare-s3-for-vds.arn}:$LATEST",
        "Payload": {
          "src": "vds/prev_tmp"
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
        "FunctionName": "${module.lambda-prepare-s3-for-vds.arn}:$LATEST",
        "Payload": {
          "src": "vds/prev",
          "dst": "vds/prev_tmp"
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
          "src": "vds/current",
          "dst": "vds/prev"
        },
        "FunctionName": "${module.lambda-prepare-s3-for-vds.arn}:$LATEST"
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
      "Next": "IC list for parallel load of VDS data"
    },
    "IC list for parallel load of VDS data": {
      "Type": "Pass",
      "Next": "Map",
      "Result": {
        "IC": [
          {
            "ic": "NCI",
            "divisions": [
              "NCI CCR"
            ],
            "includeDivisions": true,
            "name": "NCI_CCR"
          },
          {
            "ic": "NCI",
            "divisions": [
              "NCI OD"
            ],
            "includeDivisions": true,
            "name": "NCI_OD"
          },
          {
            "ic": "NCI",
            "divisions": [
              "NCI OD",
              "NCI CCR"
            ],
            "includeDivisions": false,
            "name": "NCI_OTHER"
          },
          {
            "ic": "OD"
          },
          {
            "ic": "NIAID"
          },
          {
            "ic": "CC"
          },
          {
            "ic": "CIT"
          },
          {
            "ic": "CSR"
          },
          {
            "ic": "FIC"
          },
          {
            "ic": "NCATS"
          },
          {
            "ic": "NCCIH"
          },
          {
            "ic": "NEI"
          },
          {
            "ic": "NHGRI"
          },
          {
            "ic": "NHLBI"
          },
          {
            "ic": "NIA"
          },
          {
            "ic": "NIAAA"
          },
          {
            "ic": "NIAMS"
          },
          {
            "ic": "NIBIB"
          },
          {
            "ic": "NICHD"
          },
          {
            "ic": "NIDA"
          },
          {
            "ic": "NIDCD"
          },
          {
            "ic": "NIDCR"
          },
          {
            "ic": "NIDDK"
          },
          {
            "ic": "NIEHS"
          },
          {
            "ic": "NIGMS"
          },
          {
            "ic": "NIMH"
          },
          {
            "ic": "NIMHD"
          },
          {
            "ic": "NINDS"
          },
          {
            "ic": "NINR"
          },
          {
            "ic": "NLM"
          }
        ]
      }
    },
    "Map": {
      "Type": "Map",
      "Iterator": {
        "StartAt": "Load VDS users for the given IC",
        "States": {
          "Load VDS users for the given IC": {
            "Type": "Task",
            "Resource": "arn:aws:states:::lambda:invoke",
            "OutputPath": "$.Payload",
            "Parameters": {
              "Payload.$": "$",
              "FunctionName": "${module.lambda-load-from-vds.arn}:$LATEST"
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
            "End": true
          }
        }
      },
      "ItemsPath": "$.IC",
      "Catch": [
        {
          "ErrorEquals": [
            "States.ALL"
          ],
          "Next": "Clean up current folder",
          "Comment": "VDS load failed"
        }
      ],
      "Next": "Calculate deltas with Athena",
      "MaxConcurrency": 4
    },
    "Calculate deltas with Athena": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-vds-users-delta.arn}:$LATEST",
        "Payload": {
          "DB_NAME": "vdsdb_dev",
          "S3SUBFOLDER": "vds",
          "DB_CURRENT_T": "currentp_t",
          "DB_PREV_T": "prevp_t"
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
        "FunctionName": "${module.lambda-delta-to-sqs.arn}:$LATEST",
        "Payload": {
          "delta.$": "$.delta",
          "deleted.$": "$.deleted",
          "sqs_url_key": "VDS_SQS_URL"
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
        "FunctionName": "${module.lambda-prepare-s3-for-vds.arn}:$LATEST",
        "Payload": {
          "src": "vds/current"
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
        "FunctionName": "${module.lambda-prepare-s3-for-vds.arn}:$LATEST",
        "Payload": {
          "src": "vds/prev",
          "dst": "vds/current"
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
        "FunctionName": "${module.lambda-prepare-s3-for-vds.arn}:$LATEST",
        "Payload": {
          "src": "vds/prev_tmp",
          "dst": "vds/prev"
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
      "Cause": "VDS load failed"
    }
  }
}
EOF
}

resource "aws_sfn_state_machine" "edis_sfn_rollback" {
  name       = "edis-rollback-${var.env}"
  role_arn   = aws_iam_role.step_function.arn
  definition = <<EOF
{
  "Comment": "Rollback VDS data to current folder",
  "StartAt": "Clean up current",
  "States": {
    "Clean up current": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-prepare-s3-for-vds.arn}:$LATEST",
        "Payload": {
          "src": "vds/current"
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
      "Next": "From prev to current"
    },
    "From prev to current": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-prepare-s3-for-vds.arn}:$LATEST",
        "Payload": {
          "src": "vds/prev",
          "dst": "vds/current"
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
      "Next": "From prev_tmp to prev"
    },
    "From prev_tmp to prev": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${module.lambda-prepare-s3-for-vds.arn}:$LATEST",
        "Payload": {
          "src": "vds/prev_tmp",
          "dst": "vds/prev"
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
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_rule" "edis_refresh_vds" {
  name = "edis-vds-refresh-${var.env}"
  description = "Start Step Function to refresh VDS user data"
  schedule_expression = lookup(local.tier_conf, var.env).step_cron
}

resource "aws_cloudwatch_event_target" "edis_refresh_vds" {
  arn  = aws_sfn_state_machine.edis_sfn_refresh_vds.arn
  rule = aws_cloudwatch_event_rule.edis_refresh_vds.name
  role_arn = aws_iam_role.refresh_vds_trigger.arn
}