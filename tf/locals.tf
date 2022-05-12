locals {
  OktaMap = tomap({
    dev = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    dev2 = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    test = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    qa = {
      issuer   = "https://nih-nci.oktapreview.com/oauth2/aus13y2f31cSMywhw0h8"
      audience = "api://default"
    }
    stage = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
    }
    prod = {
      issuer   = "https://iam.cancer.gov/oauth2/ausb533gx0oJEKboc297"
      audience = "api://default"
    }
  })

  resource_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "execute-api:Invoke",
      "Resource": "execute-api:/*/*/*"
    },
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "execute-api:Invoke",
      "Resource": "execute-api:/*/*/*",
      "Condition": {
        "NotIpAddress": {
          "aws:SourceIp": [
            "128.231.0.0/16",
            "156.40.216.3/32",
            "156.40.216.1/32",
            "52.115.248.9",
            "149.96.193.8/29",
            "149.96.192.8/29",
            "149.96.193.8/29"
          ]
        }
      }
    }
  ]
}
EOF

}

data "template_file" "api_swagger" {
  template = file("modules/lambda/tf-swagger-userapi-v3.yaml")

  vars = {
    lambda_arn = module.lambda.lambda_arn
    ddb_action_get_item = "arn:aws:apigateway:us-east-1:dynamodb:action/GetItem"
    ddb_action_scan = "arn:aws:apigateway:us-east-1:dynamodb:action/Scan"
    ddb_action_query = "arn:aws:apigateway:us-east-1:dynamodb:action/Query"
    ddb_role_arn = module.ddb-extusers.iam-access-ddb-role-arn
    users_table_name = module.ddb-extusers.ddb-extusers-name
  }
}

