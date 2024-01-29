# vpc-nfw

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.0 |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws.mgmt"></a> [aws.mgmt](#provider\_aws.mgmt) | ~> 5.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mgmt_subnet_addrs"></a> [mgmt\_subnet\_addrs](#module\_mgmt\_subnet\_addrs) | hashicorp/subnets/cidr | v1.0.0 |
| <a name="module_mgmt_vpc"></a> [mgmt\_vpc](#module\_mgmt\_vpc) | ../ | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.nfw_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.nfw_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.nfw_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to create resources in. | `string` | n/a | yes |
| <a name="input_cidrs_for_remote_access"></a> [cidrs\_for\_remote\_access](#input\_cidrs\_for\_remote\_access) | List of IPv4 CIDR ranges to access all admins remote access | `list(string)` | n/a | yes |
| <a name="input_delete_protection"></a> [delete\_protection](#input\_delete\_protection) | Whether or not to enable deletion protection of NFW | `bool` | `true` | no |
| <a name="input_mgmt_vpc_cidr"></a> [mgmt\_vpc\_cidr](#input\_mgmt\_vpc\_cidr) | The CIDR range of the VPC | `string` | n/a | yes |
| <a name="input_profile"></a> [profile](#input\_profile) | The AWS profile aligned with the AWS environment to deploy to | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | A prefix that should be attached to the names of resources | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->