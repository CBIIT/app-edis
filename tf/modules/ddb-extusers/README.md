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
| [aws_dynamodb_table.extusers-table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_policy.iam_access_ddb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.iam_access_ddb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_policy_document.assume_role_api_gateway_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.iam_access_ddb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | `""` | no |
| <a name="input_must-be-policy-arn"></a> [must-be-policy-arn](#input\_must-be-policy-arn) | Mandatory boundary policy to be included in any IAM role | `string` | `""` | no |
| <a name="input_must-be-role-prefix"></a> [must-be-role-prefix](#input\_must-be-role-prefix) | Mandatory IAM role name prefix | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ddb-extusers-arn"></a> [ddb-extusers-arn](#output\_ddb-extusers-arn) | n/a |
| <a name="output_ddb-extusers-name"></a> [ddb-extusers-name](#output\_ddb-extusers-name) | n/a |
| <a name="output_iam-access-ddb-role-arn"></a> [iam-access-ddb-role-arn](#output\_iam-access-ddb-role-arn) | n/a |
<!-- END_TF_DOCS -->