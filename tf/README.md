# Enterprise Data & Integration Services Web Services

## Terraform scripts deployment

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.21.0 |
| <a name="provider_template"></a> [template](#provider\_template) | 2.2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_api-gateway-era-commons"></a> [api-gateway-era-commons](#module\_api-gateway-era-commons) | ./modules/api-gateway | n/a |
| <a name="module_api-gateway-userinfo"></a> [api-gateway-userinfo](#module\_api-gateway-userinfo) | ./modules/api-gateway | n/a |
| <a name="module_ddb-extusers"></a> [ddb-extusers](#module\_ddb-extusers) | ./modules/ddb-extusers | n/a |
| <a name="module_ddb-userinfo"></a> [ddb-userinfo](#module\_ddb-userinfo) | ./modules/ddb-userinfo | n/a |
| <a name="module_lambda-era-commons-api"></a> [lambda-era-commons-api](#module\_lambda-era-commons-api) | ./modules/lambda | n/a |
| <a name="module_lambda-load-from-vds"></a> [lambda-load-from-vds](#module\_lambda-load-from-vds) | ./modules/lambda | n/a |
| <a name="module_lambda-prepare-s3-for-vds"></a> [lambda-prepare-s3-for-vds](#module\_lambda-prepare-s3-for-vds) | ./modules/lambda | n/a |
| <a name="module_lambda-userinfo-api"></a> [lambda-userinfo-api](#module\_lambda-userinfo-api) | ./modules/lambda | n/a |
| <a name="module_lambda-vds-users-delta"></a> [lambda-vds-users-delta](#module\_lambda-vds-users-delta) | ./modules/lambda | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.iam_access_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.step_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_policy_document.assume_role_step_function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.iam_access_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [template_file.api_era-commons-swagger](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.api_userinfo_swagger](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_build-eracommons"></a> [build-eracommons](#input\_build-eracommons) | Set to true to deploy era commons API related resources | `bool` | `false` | no |
| <a name="input_build-userinfo"></a> [build-userinfo](#input\_build-userinfo) | Set to true to deploy user info API related resources | `bool` | `false` | no |
| <a name="input_env"></a> [env](#input\_env) | Environment tier | `string` | `"dev"` | no |
| <a name="input_policy-boundary-arn"></a> [policy-boundary-arn](#input\_policy-boundary-arn) | Must be policy to include in any IAM role | `string` | `""` | no |
| <a name="input_role-prefix"></a> [role-prefix](#input\_role-prefix) | Must be prefix to any IAM role | `string` | `"power-user-edis"` | no |
| <a name="input_s3bucket-for-vds-users"></a> [s3bucket-for-vds-users](#input\_s3bucket-for-vds-users) | S3 Bucket name to load users info from VDS | `string` | n/a | yes |
| <a name="input_subnet1"></a> [subnet1](#input\_subnet1) | VPC Subnet 1 id for Lambda functions placed inside VPC | `string` | n/a | yes |
| <a name="input_subnet2"></a> [subnet2](#input\_subnet2) | VPC Subnet 2 id for Lambda functions placed inside VPC | `string` | n/a | yes |
| <a name="input_vpcsg"></a> [vpcsg](#input\_vpcsg) | Security Group id for Lambda functions placed inside VPC | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->