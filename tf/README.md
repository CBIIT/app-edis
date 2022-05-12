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
| <a name="module_api-gateway"></a> [api-gateway](#module\_api-gateway) | ./modules/api-gateway | n/a |
| <a name="module_ddb-extusers"></a> [ddb-extusers](#module\_ddb-extusers) | ./modules/ddb-extusers | n/a |
| <a name="module_lambda"></a> [lambda](#module\_lambda) | ./modules/lambda | n/a |

## Resources

| Name | Type |
|------|------|
| [template_file.api_swagger](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_env"></a> [env](#input\_env) | Environment tier | `string` | `"dev"` | no |
| <a name="input_policy-boundary-arn"></a> [policy-boundary-arn](#input\_policy-boundary-arn) | Must be policy to include in any IAM role | `string` | `""` | no |
| <a name="input_role-prefix"></a> [role-prefix](#input\_role-prefix) | Must be prefix to any IAM role | `string` | `"power-user"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->