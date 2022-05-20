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
| <a name="provider_template"></a> [template](#provider\_template) | 2.2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_api-gateway-era-commons"></a> [api-gateway-era-commons](#module\_api-gateway-era-commons) | ./modules/api-gateway | n/a |
| <a name="module_api-gateway-userinfo"></a> [api-gateway-userinfo](#module\_api-gateway-userinfo) | ./modules/api-gateway | n/a |
| <a name="module_ddb-extusers"></a> [ddb-extusers](#module\_ddb-extusers) | ./modules/ddb-extusers | n/a |
| <a name="module_lambda-era-commons-api"></a> [lambda-era-commons-api](#module\_lambda-era-commons-api) | ./modules/lambda | n/a |
| <a name="module_lambda-userinfo-api"></a> [lambda-userinfo-api](#module\_lambda-userinfo-api) | ./modules/lambda | n/a |

## Resources

| Name | Type |
|------|------|
| [template_file.api_era-commons-swagger](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.api_userinfo_swagger](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | Environment tier | `string` | `"dev"` | no |
| <a name="input_policy-boundary-arn"></a> [policy-boundary-arn](#input\_policy-boundary-arn) | Must be policy to include in any IAM role | `string` | `""` | no |
| <a name="input_role-prefix"></a> [role-prefix](#input\_role-prefix) | Must be prefix to any IAM role | `string` | `"power-user-edis"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->