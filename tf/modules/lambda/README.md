<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.iam_for_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.iam_for_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function_event_invoke_config.lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_event_invoke_config) | resource |
| [aws_lambda_permission._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_permission) | resource |
| [aws_caller_identity._](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.assume_role_lambda_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_gateway_rest_api_id"></a> [api\_gateway\_rest\_api\_id](#input\_api\_gateway\_rest\_api\_id) | API Gateway REST API identifier, default null | `string` | `null` | no |
| <a name="input_app"></a> [app](#input\_app) | Name of the application | `any` | n/a | yes |
| <a name="input_create_api_gateway_integration"></a> [create\_api\_gateway\_integration](#input\_create\_api\_gateway\_integration) | If we integrate with API Gateway, enable this. Default disabled | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | Deployment tier (dev/test/qa/stage/prod/etc.) | `any` | n/a | yes |
| <a name="input_file-name"></a> [file-name](#input\_file-name) | Name of the zip file with lambda function body | `any` | n/a | yes |
| <a name="input_lambda-description"></a> [lambda-description](#input\_lambda-description) | Lambda function description | `string` | `""` | no |
| <a name="input_lambda-env-variables"></a> [lambda-env-variables](#input\_lambda-env-variables) | List of environment variables for lambda function | `map(string)` | `{}` | no |
| <a name="input_lambda-managed-policies"></a> [lambda-managed-policies](#input\_lambda-managed-policies) | List of AWS or customer managed policies to attach to lambda iam role | `list(string)` | <pre>[<br>  "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"<br>]</pre> | no |
| <a name="input_lambda-name"></a> [lambda-name](#input\_lambda-name) | Partial name of the Lambda function - the full name consists of app, lambda-name, and env strings separated by '-' | `any` | n/a | yes |
| <a name="input_max-retry"></a> [max-retry](#input\_max-retry) | Maxumim retry attempts | `number` | `0` | no |
| <a name="input_must-be-policy-arn"></a> [must-be-policy-arn](#input\_must-be-policy-arn) | Mandatory policy to be included in any IAM role | `any` | n/a | yes |
| <a name="input_must-be-role-prefix"></a> [must-be-role-prefix](#input\_must-be-role-prefix) | Mandatory IAM role name prefix | `any` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `any` | n/a | yes |
| <a name="input_resource_tag_name"></a> [resource\_tag\_name](#input\_resource\_tag\_name) | Value of tag 'Name' for cost/resource tracking | `any` | n/a | yes |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | List of EC2 security groups ids for Lambda function inside VPC | `list(string)` | `[]` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of EC2 subnet ids for Lambda function inside VPC | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | n/a |
| <a name="output_invoke_arn"></a> [invoke\_arn](#output\_invoke\_arn) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
<!-- END_TF_DOCS -->