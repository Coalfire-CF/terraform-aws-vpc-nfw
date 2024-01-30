# vpc-nfw

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.5.5 |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.5.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.15.0, < 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.34.0 |
| <a name="provider_aws.mgmt"></a> [aws.mgmt](#provider\_aws.mgmt) | 5.34.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_mgmt_subnet_addrs"></a> [mgmt\_subnet\_addrs](#module\_mgmt\_subnet\_addrs) | hashicorp/subnets/cidr | v1.0.0 |
| <a name="module_mgmt_vpc"></a> [mgmt\_vpc](#module\_mgmt\_vpc) | ../../. | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_kms_alias.cloudwatch_key_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_alias.nfw_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.cloudwatch_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.nfw_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.cloudwatch_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.nfw_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | The AWS region to create resources in. | `string` | n/a | yes |
| <a name="input_cidrs_for_remote_access"></a> [cidrs\_for\_remote\_access](#input\_cidrs\_for\_remote\_access) | List of IPv4 CIDR ranges to access all admins remote access | `list(string)` | n/a | yes |
| <a name="input_delete_protection"></a> [delete\_protection](#input\_delete\_protection) | Whether or not to enable deletion protection of NFW | `bool` | `true` | no |
| <a name="input_deploy_aws_nfw"></a> [deploy\_aws\_nfw](#input\_deploy\_aws\_nfw) | enable nfw true/false | `bool` | `false` | no |
| <a name="input_mgmt_vpc_cidr"></a> [mgmt\_vpc\_cidr](#input\_mgmt\_vpc\_cidr) | The CIDR range of the VPC | `string` | n/a | yes |
| <a name="input_profile"></a> [profile](#input\_profile) | The AWS profile aligned with the AWS environment to deploy to | `string` | n/a | yes |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | A prefix that should be attached to the names of resources | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_nfw_endpoint_ids"></a> [aws\_nfw\_endpoint\_ids](#output\_aws\_nfw\_endpoint\_ids) | List of IDs of AWS NFW endpoints |
| <a name="output_database_route_table_ids"></a> [database\_route\_table\_ids](#output\_database\_route\_table\_ids) | List of IDs of database route tables |
| <a name="output_database_subnet_group"></a> [database\_subnet\_group](#output\_database\_subnet\_group) | ID of database subnet group |
| <a name="output_database_subnets"></a> [database\_subnets](#output\_database\_subnets) | List of IDs of database subnets |
| <a name="output_database_subnets_cidr_blocks"></a> [database\_subnets\_cidr\_blocks](#output\_database\_subnets\_cidr\_blocks) | List of cidr\_blocks of database subnets |
| <a name="output_default_network_acl_id"></a> [default\_network\_acl\_id](#output\_default\_network\_acl\_id) | The ID of the default network ACL |
| <a name="output_default_route_table_id"></a> [default\_route\_table\_id](#output\_default\_route\_table\_id) | The ID of the default route table |
| <a name="output_default_security_group_id"></a> [default\_security\_group\_id](#output\_default\_security\_group\_id) | The ID of the security group created by default on VPC creation |
| <a name="output_default_vpc_cidr_block"></a> [default\_vpc\_cidr\_block](#output\_default\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_default_vpc_default_network_acl_id"></a> [default\_vpc\_default\_network\_acl\_id](#output\_default\_vpc\_default\_network\_acl\_id) | The ID of the default network ACL |
| <a name="output_default_vpc_default_route_table_id"></a> [default\_vpc\_default\_route\_table\_id](#output\_default\_vpc\_default\_route\_table\_id) | The ID of the default route table |
| <a name="output_default_vpc_default_security_group_id"></a> [default\_vpc\_default\_security\_group\_id](#output\_default\_vpc\_default\_security\_group\_id) | The ID of the security group created by default on VPC creation |
| <a name="output_default_vpc_enable_dns_hostnames"></a> [default\_vpc\_enable\_dns\_hostnames](#output\_default\_vpc\_enable\_dns\_hostnames) | Whether or not the VPC has DNS hostname support |
| <a name="output_default_vpc_enable_dns_support"></a> [default\_vpc\_enable\_dns\_support](#output\_default\_vpc\_enable\_dns\_support) | Whether or not the VPC has DNS support |
| <a name="output_default_vpc_id"></a> [default\_vpc\_id](#output\_default\_vpc\_id) | The ID of the VPC |
| <a name="output_default_vpc_instance_tenancy"></a> [default\_vpc\_instance\_tenancy](#output\_default\_vpc\_instance\_tenancy) | Tenancy of instances spin up within VPC |
| <a name="output_default_vpc_main_route_table_id"></a> [default\_vpc\_main\_route\_table\_id](#output\_default\_vpc\_main\_route\_table\_id) | The ID of the main route table associated with this VPC |
| <a name="output_elasticache_route_table_ids"></a> [elasticache\_route\_table\_ids](#output\_elasticache\_route\_table\_ids) | List of IDs of elasticache route tables |
| <a name="output_elasticache_subnet_group"></a> [elasticache\_subnet\_group](#output\_elasticache\_subnet\_group) | ID of elasticache subnet group |
| <a name="output_elasticache_subnet_group_name"></a> [elasticache\_subnet\_group\_name](#output\_elasticache\_subnet\_group\_name) | Name of elasticache subnet group |
| <a name="output_elasticache_subnets"></a> [elasticache\_subnets](#output\_elasticache\_subnets) | List of IDs of elasticache subnets |
| <a name="output_elasticache_subnets_cidr_blocks"></a> [elasticache\_subnets\_cidr\_blocks](#output\_elasticache\_subnets\_cidr\_blocks) | List of cidr\_blocks of elasticache subnets |
| <a name="output_firewall_route_table_ids"></a> [firewall\_route\_table\_ids](#output\_firewall\_route\_table\_ids) | List of IDs of firewall route tables |
| <a name="output_firewall_subnets"></a> [firewall\_subnets](#output\_firewall\_subnets) | List of IDs of firewall subnets |
| <a name="output_firewall_subnets_cidr_blocks"></a> [firewall\_subnets\_cidr\_blocks](#output\_firewall\_subnets\_cidr\_blocks) | List of cidr\_blocks of firewall subnets |
| <a name="output_igw_id"></a> [igw\_id](#output\_igw\_id) | The ID of the Internet Gateway |
| <a name="output_intra_route_table_ids"></a> [intra\_route\_table\_ids](#output\_intra\_route\_table\_ids) | List of IDs of intra route tables |
| <a name="output_intra_subnets"></a> [intra\_subnets](#output\_intra\_subnets) | List of IDs of intra subnets |
| <a name="output_intra_subnets_cidr_blocks"></a> [intra\_subnets\_cidr\_blocks](#output\_intra\_subnets\_cidr\_blocks) | List of cidr\_blocks of intra subnets |
| <a name="output_nat_ids"></a> [nat\_ids](#output\_nat\_ids) | List of allocation ID of Elastic IPs created for AWS NAT Gateway |
| <a name="output_nat_public_ips"></a> [nat\_public\_ips](#output\_nat\_public\_ips) | List of public Elastic IPs created for AWS NAT Gateway |
| <a name="output_natgw_ids"></a> [natgw\_ids](#output\_natgw\_ids) | List of NAT Gateway IDs |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | List of IDs of private route tables |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of IDs of private subnets |
| <a name="output_private_subnets_cidr_blocks"></a> [private\_subnets\_cidr\_blocks](#output\_private\_subnets\_cidr\_blocks) | List of cidr\_blocks of private subnets |
| <a name="output_public_subnets"></a> [public\_subnets](#output\_public\_subnets) | List of IDs of public subnets |
| <a name="output_public_subnets_cidr_blocks"></a> [public\_subnets\_cidr\_blocks](#output\_public\_subnets\_cidr\_blocks) | List of cidr\_blocks of public subnets |
| <a name="output_redshift_route_table_ids"></a> [redshift\_route\_table\_ids](#output\_redshift\_route\_table\_ids) | List of IDs of redshift route tables |
| <a name="output_redshift_subnet_group"></a> [redshift\_subnet\_group](#output\_redshift\_subnet\_group) | ID of redshift subnet group |
| <a name="output_redshift_subnets"></a> [redshift\_subnets](#output\_redshift\_subnets) | List of IDs of redshift subnets |
| <a name="output_redshift_subnets_cidr_blocks"></a> [redshift\_subnets\_cidr\_blocks](#output\_redshift\_subnets\_cidr\_blocks) | List of cidr\_blocks of redshift subnets |
| <a name="output_tgw_route_table_ids"></a> [tgw\_route\_table\_ids](#output\_tgw\_route\_table\_ids) | List of IDs of tgw route tables |
| <a name="output_tgw_subnets"></a> [tgw\_subnets](#output\_tgw\_subnets) | List of IDs of tgw subnets |
| <a name="output_tgw_subnets_cidr_blocks"></a> [tgw\_subnets\_cidr\_blocks](#output\_tgw\_subnets\_cidr\_blocks) | List of cidr\_blocks of tgw subnets |
| <a name="output_vgw_id"></a> [vgw\_id](#output\_vgw\_id) | The ID of the VPN Gateway |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | The CIDR block of the VPC |
| <a name="output_vpc_enable_dns_hostnames"></a> [vpc\_enable\_dns\_hostnames](#output\_vpc\_enable\_dns\_hostnames) | Whether or not the VPC has DNS hostname support |
| <a name="output_vpc_enable_dns_support"></a> [vpc\_enable\_dns\_support](#output\_vpc\_enable\_dns\_support) | Whether or not the VPC has DNS support |
| <a name="output_vpc_endpoint_dynamodb_id"></a> [vpc\_endpoint\_dynamodb\_id](#output\_vpc\_endpoint\_dynamodb\_id) | The ID of VPC endpoint for DynamoDB |
| <a name="output_vpc_endpoint_dynamodb_pl_id"></a> [vpc\_endpoint\_dynamodb\_pl\_id](#output\_vpc\_endpoint\_dynamodb\_pl\_id) | The prefix list for the DynamoDB VPC endpoint. |
| <a name="output_vpc_endpoint_s3_id"></a> [vpc\_endpoint\_s3\_id](#output\_vpc\_endpoint\_s3\_id) | The ID of VPC endpoint for S3 |
| <a name="output_vpc_endpoint_s3_pl_id"></a> [vpc\_endpoint\_s3\_pl\_id](#output\_vpc\_endpoint\_s3\_pl\_id) | The prefix list for the S3 VPC endpoint. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
| <a name="output_vpc_instance_tenancy"></a> [vpc\_instance\_tenancy](#output\_vpc\_instance\_tenancy) | Tenancy of instances spin up within VPC |
| <a name="output_vpc_main_route_table_id"></a> [vpc\_main\_route\_table\_id](#output\_vpc\_main\_route\_table\_id) | The ID of the main route table associated with this VPC |
| <a name="output_vpc_secondary_cidr_blocks"></a> [vpc\_secondary\_cidr\_blocks](#output\_vpc\_secondary\_cidr\_blocks) | List of secondary CIDR blocks of the VPC |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
