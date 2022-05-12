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
| [aws_api_gateway_account.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_account) | resource |
| [aws_api_gateway_authorizer.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_authorizer) | resource |
| [aws_api_gateway_deployment.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_deployment) | resource |
| [aws_api_gateway_method_settings.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_settings) | resource |
| [aws_api_gateway_rest_api.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api) | resource |
| [aws_api_gateway_rest_api_policy.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_rest_api_policy) | resource |
| [aws_api_gateway_stage.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_stage) | resource |
| [aws_cloudwatch_log_group.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_iam_role.api_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.auth_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_lambda_function.auth_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function_event_invoke_config.auth_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function_event_invoke_config) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api-resource-policy"></a> [api-resource-policy](#input\_api-resource-policy) | Optional resource policy to be applied to api gateway | `string` | `""` | no |
| <a name="input_api-swagger"></a> [api-swagger](#input\_api-swagger) | The rendered OpenAPI specification that defines the set of routes and integrations to create as part of the REST API. | `string` | `""` | no |
| <a name="input_app-description"></a> [app-description](#input\_app-description) | Description of API Gateway project | `string` | `""` | no |
| <a name="input_app-name"></a> [app-name](#input\_app-name) | Name of the project that will be assigned as a tag to every resource of the project, also used in API Gateway API name | `string` | `"apigateway"` | no |
| <a name="input_env"></a> [env](#input\_env) | The deployment tier (dev/test/qa/stage/prod and others) | `string` | `""` | no |
| <a name="input_must-be-policy-arn"></a> [must-be-policy-arn](#input\_must-be-policy-arn) | Mandatory policy to be included in any IAM role | `string` | `""` | no |
| <a name="input_must-be-role-prefix"></a> [must-be-role-prefix](#input\_must-be-role-prefix) | Mandatory IAM role name prefix | `string` | `""` | no |
| <a name="input_okta-audience"></a> [okta-audience](#input\_okta-audience) | AUDIENCE for OKTA provider authentication server | `string` | `"api://default"` | no |
| <a name="input_okta-issuer"></a> [okta-issuer](#input\_okta-issuer) | URL to OKTA provider authentication server | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_url"></a> [url](#output\_url) | n/a |
<!-- END_TF_DOCS -->