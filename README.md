![Coalfire](coalfire_logo.png)

# terraform-aws-vpc-nfw

## Description

Terraform module which creates VPC and/or NFW resources on AWS.

## Dependencies

- terraform-aws-account-setup

## Resource List

The following type of resources are supported:

* [VPC](https://www.terraform.io/docs/providers/aws/r/vpc.html)
* [Subnet](https://www.terraform.io/docs/providers/aws/r/subnet.html)
* [Route](https://www.terraform.io/docs/providers/aws/r/route.html)
* [Route table](https://www.terraform.io/docs/providers/aws/r/route_table.html)
* [Internet Gateway](https://www.terraform.io/docs/providers/aws/r/internet_gateway.html)
* [NAT Gateway](https://www.terraform.io/docs/providers/aws/r/nat_gateway.html)
* [VPN Gateway](https://www.terraform.io/docs/providers/aws/r/vpn_gateway.html)
* [VPC Endpoint](https://www.terraform.io/docs/providers/aws/r/vpc_endpoint.html) (
  S3
  and
  DynamoDB)
* [RDS DB Subnet Group](https://www.terraform.io/docs/providers/aws/r/db_subnet_group.html)
* [ElastiCache Subnet Group](https://www.terraform.io/docs/providers/aws/r/elasticache_subnet_group.html)
* [Redshift Subnet Group](https://www.terraform.io/docs/providers/aws/r/redshift_subnet_group.html)
* [DHCP Options Set](https://www.terraform.io/docs/providers/aws/r/vpc_dhcp_options.html)
* [Default VPC](https://www.terraform.io/docs/providers/aws/r/default_vpc.html)
* [AWS NFW](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall)

## Assumptions

* Networking resources, including VPCs, Transit Gateways and Network Firewalls, are designed to be deployed under a single state.
* Outputs of this module can be referenced via terraform state in the following manner:
  * `module.mgmt_vpc.private_subnets["mvp-mgmt-compute-us-gov-west-1a"]`
  * `data.terraform_remote_state.network.outputs.public_subnets["mvp-mgmt-dmz-us-gov-west-1a"]`
* This is designed to automatically reference the firewall subnets when opted to be created.
* Automatically adds AWS region to the subnet name upon creation.
* The private route table IDs includes the route table IDs from database subnets as well.

## Replacing the Default Deny All NFW Policy

#### There will be a default Deny All NFW policy that is applied `module.mgmt_vpc.module.aws_network_firewall.nfw-base-suricata-rule.json`. If you are having networking problems, please follow the example below of how to pass a customized ruleset to the module. Any customized ruleset will overwrite the default policy.

1. Copy the `test.rules.json` file to the directory running terraform and name give it a name. For this example I will use `suricata.json`.
2. Populate this json file in a similar format to the `test.rules.json`, adding ports and domains that you need open based on tooling or client need.
3. In your `nfw-policies.tf` file, create a local variable called `suricata_rule_group_shrd_svcs` and populate values like this example:
```
  suricata_rule_group_shrd_svcs = [
    {
      capacity    = 1000
      name        = "SuricataDenyAll"
      description = "DenyAllRules"
      rules_file  = file("./suricata.json")
    }
  ]
```
4. In the file that you reference the module, add a line similar to the one shown in this example. This will pass your custom Suricata ruleset to the module, overwriting the default ruleset.
```  
aws_nfw_suricata_stateful_rule_group = local.suricata_rule_group_shrd_svcs
```
5. After you have built your packer images, come back and remove the following line:
```  
pass tcp $EXTERNAL_NET any -> $HOME_NET 22 (msg:"Allow inbound SSH - ONLY FOR PACKER DISABLE AFTER IMAGES ARE BUILT"; flow:established; sid:103; rev:1;)
```

## Custom Routes

There are variables provided for each subnet type:

- database_custom_routes
- elasticache_custom_routes
- firewall_custom_routes
- intra_custom_routes
- private_custom_routes
- public_custom_routes
- redshift_custom_routes

These variables are lists of objects.

Example of custom public routes:

```hcl
public_custom_routes = [
    {
      destination_cidr_block = "8.8.8.8/32"
      internet_route              = true
    },
    {
      destination_cidr_block = "4.4.4.4/32"
      internet_route              = true
    }
  ]
```

An "internet_route" boolean sets a default to send traffic to the created IGW as a target (required), or to the NFW endpoint if created.

Some variables expose different expected values based on sensible assumptions.  For example, a public custom route would not expose NAT gateway as a target, and likewise private subnets will not allow Internet Gateway to be a target.

The variables can be further inspected to see what parameters and types are expected.

## Usage
If networks are being created with the goal of peering, it is best practice to build and deploy those resources within the same Terraform state. This allows for efficient referencing of peer subnets and CIDRs to facilitate a proper routing architecture.
Please refer to the 'example' folder for example files needed on the parent module calling this PAK based on the deployment requirements. An example of 'mgmt.tf' usage is shown:
```hcl
module "mgmt_vpc" {
  source = "github.com/Coalfire-CF/terraform-aws-vpc-nfw"

  name = "${var.resource_prefix}-mgmt"

  delete_protection = var.delete_protection

  cidr = var.mgmt_vpc_cidr

  azs = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]

  private_subnets = local.private_subnets # Map of Name -> CIDR
  private_subnet_tags = {
    "0" = "Compute"
    "1" = "Compute"
    "2" = "Compute"
    "3" = "Private"
    "4" = "Private"
    "5" = "Private"
  }

  tgw_subnets = local.tgw_subnets
  tgw_subnet_tags = {
    "0" = "TGW"
    "1" = "TGW"
    "2" = "TGW"
  }
  
  public_subnets       = local.public_subnets # Map of Name -> CIDR
  public_subnet_suffix = "public"

  single_nat_gateway     = false
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true

  flow_log_destination_type              = "cloud-watch-logs"
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_kms_key_id        = data.terraform_remote_state.account-setup.outputs.cloudwatch_kms_key_arn

  ### Network Firewall ###
  deploy_aws_nfw                        = true
  aws_nfw_prefix                        = var.resource_prefix
  aws_nfw_name                          = "${var.resource_prefix}-nfw"
  aws_nfw_fivetuple_stateful_rule_group = local.fivetuple_rule_group
  aws_nfw_suricata_stateful_rule_group  = local.suricata_rule_group_shrd_svcs
  nfw_kms_key_id                        = data.terraform_remote_state.account-setup.outputs.nfw_kms_key_id

  #When deploying NFW, firewall_subnets must be specified
  firewall_subnets       = local.firewall_subnets
  firewall_subnet_suffix = "firewall"

  # TLS Outbound Inspection
  enable_tls_inspection = var.enable_tls_inspection # deploy_aws_nfw must be set to true to enable this
  tls_cert_arn          = var.tls_cert_arn
  tls_destination_cidrs = var.tls_destination_cidrs # Set these to the NAT gateways to filter outbound traffic without affecting the hosted VPN

  ### VPC Endpoints ###
  create_vpc_endpoints = true

  # Control where gateway endpoints are associated
  associate_with_private_route_tables = true  # Associate with private subnets (default)
  associate_with_public_route_tables  = false # Don't associate with public subnets

  vpc_endpoints = {
    # S3 Gateway endpoint
    s3 = {
      service_type = "Gateway"
      service_name = "com.amazonaws.${var.aws_region}.s3"
      tags         = { Name = "${var.resource_prefix}-s3-endpoint" }
    }

    # DynamoDB Gateway endpoint
    dynamodb = {
      service_type = "Gateway"
      service_name = "com.amazonaws.${var.aws_region}.dynamodb"
      tags         = { Name = "${var.resource_prefix}-dynamodb-endpoint" }
    }

    # KMS Interface endpoint (for encryption operations)
    kms = {
      service_type        = "Interface"
      service_name        = "com.amazonaws.${var.aws_region}.kms-fips"
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-kms-endpoint" }
    }
  }

  # Define a common security group for the VPC endpoints
  vpc_endpoint_security_groups = {
    common_sg = {
      name        = "common-endpoint-sg"
      description = "Common security group for all VPC endpoints"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = var.cidr_block #should just allow your vpc_cidr
        }
      ]
    }
  }
  
  /* Add Additional tags here */
  tags = {
    Owner       = var.resource_prefix
    Environment = "mgmt"
    createdBy   = "terraform"
  }
}
```
AWS Networking deployment without AWS Network Firewall:
```hcl
module "mgmt_vpc" {
  source = "github.com/Coalfire-CF/terraform-aws-vpc-nfw"

  name = "${var.resource_prefix}-mgmt"

  delete_protection = var.delete_protection

  cidr = var.mgmt_vpc_cidr

  azs = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]

  private_subnets = local.private_subnets # Map of Name -> CIDR
  private_subnet_tags = {
    "0" = "Compute"
    "1" = "Compute"
    "2" = "Compute"
    "3" = "Private"
    "4" = "Private"
    "5" = "Private"
  }

  tgw_subnets = local.tgw_subnets
  tgw_subnet_tags = {
    "0" = "TGW"
    "1" = "TGW"
    "2" = "TGW"
  }

  public_subnets       = local.public_subnets # Map of Name -> CIDR
  public_subnet_suffix = "public"

  single_nat_gateway     = false
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true

  flow_log_destination_type              = "cloud-watch-logs"
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_kms_key_id        = data.terraform_remote_state.account-setup.outputs.cloudwatch_kms_key_arn

  /* Add Additional tags here */
  tags = {
    Owner       = var.resource_prefix
    Environment = "mgmt"
    createdBy   = "terraform"
  }
}
```
## Environment Setup

```hcl
IAM user authentication:

- Download and install the AWS CLI (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Log into the AWS Console and create AWS CLI Credentials (https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)
- Configure the named profile used for the project, such as 'aws configure --profile example-mgmt'

SSO-based authentication (via IAM Identity Center SSO):

- Login to the AWS IAM Identity Center console, select the permission set for MGMT, and select the 'Access Keys' link.
- Choose the 'IAM Identity Center credentials' method to get the SSO Start URL and SSO Region values.
- Run the setup command 'aws configure sso --profile example-mgmt' and follow the prompts.
- Verify you can run AWS commands successfully, for example 'aws s3 ls --profile example-mgmt'.
- Run 'export AWS_PROFILE=example-mgmt' in your terminal to use the specific profile and avoid having to use '--profile' option.
```

## Deployment

1. Navigate to the Terraform project and create a parent directory in the upper level code, for example:

    ```hcl
    ../{CLOUD}/terraform/{REGION}/management-account/example
    ```

   If multi-account management plane:

    ```hcl
    ../{CLOUD}/terraform/{REGION}/{ACCOUNT_TYPE}-mgmt-account/example
    ```

2. Create a properly defined main.tf file via the template found under 'Usage' while adjusting 'auto.tfvars' as needed. Note that many provided variables are outputs from other modules. Example parent directory:

   ```hcl
   ├── Example/
   │   ├── example.auto.tfvars   
   │   ├── locals.tf
   │   ├── mgmt.tf
   │   ├── nfw_policies.tf
   │   ├── outputs.tf
   │   ├── providers.tf
   │   ├── remote-data.tf
   │   ├── required-providers.tf
   │   ├── subnets.tf
   │   ├── suricata.json
   │   ├── variables.tf
   │   ├── ...
   ```
    Make sure that 'remote-data.tf' defines the S3 backend which is on the Management account state bucket. For example:

    ```hcl
    terraform {
      backend "s3" {
        bucket       = "${var.resource_prefix}-us-gov-west-1-tf-state"
        region       = "us-gov-west-1"
        key          = "${var.resource_prefix}-us-gov-west-1-vpc-setup.tfstate"
        encrypt      = true
        use_lockfile = true
      }
    }
    ```

3. Initialize the Terraform working directory:
   ```hcl
   terraform init
   ```
   Create an execution plan and verify the resources being created:
   ```hcl
   terraform plan
   ```
   Apply the configuration:
   ```hcl
   terraform apply
   ```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.15.0, < 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.64.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_aws_network_firewall"></a> [aws\_network\_firewall](#module\_aws\_network\_firewall) | ./modules/aws-network-firewall | n/a |
| <a name="module_vpc_endpoints"></a> [vpc\_endpoints](#module\_vpc\_endpoints) | ./modules/vpc-endpoint | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_db_subnet_group.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_default_security_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_default_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_vpc) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_elasticache_subnet_group.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_policy.flowlogs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.flowlogs_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.flowlogs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_redshift_subnet_group.redshift](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_subnet_group) | resource |
| [aws_route.aws_nfw_igw_rt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.aws_nfw_public_internet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.database_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.elasticache_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.firewall_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.intra_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.nfw_public_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.nfw_public_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.private_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.redshift_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.tgw_custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.aws_nfw_igw_rtb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.intra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.redshift](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.intra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.nfw_igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.nfw_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.redshift](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.elasticache](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.firewall](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.intra](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.redshift](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.tgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_dhcp_options.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options) | resource |
| [aws_vpc_dhcp_options_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options_association) | resource |
| [aws_vpc_ipv4_cidr_block_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipv4_cidr_block_association) | resource |
| [aws_vpn_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway) | resource |
| [aws_vpn_gateway_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway_attachment) | resource |
| [aws_vpn_gateway_route_propagation.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway_route_propagation) | resource |
| [aws_vpn_gateway_route_propagation.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway_route_propagation) | resource |
| [aws_iam_policy_document.flow_log_cloudwatch_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vpc_flow_log_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assign_generated_ipv6_cidr_block"></a> [assign\_generated\_ipv6\_cidr\_block](#input\_assign\_generated\_ipv6\_cidr\_block) | Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block | `bool` | `false` | no |
| <a name="input_associate_with_private_route_tables"></a> [associate\_with\_private\_route\_tables](#input\_associate\_with\_private\_route\_tables) | Whether to associate Gateway endpoints with private route tables | `bool` | `true` | no |
| <a name="input_associate_with_public_route_tables"></a> [associate\_with\_public\_route\_tables](#input\_associate\_with\_public\_route\_tables) | Whether to associate Gateway endpoints with public route tables | `bool` | `false` | no |
| <a name="input_aws_nfw_domain_stateful_rule_group"></a> [aws\_nfw\_domain\_stateful\_rule\_group](#input\_aws\_nfw\_domain\_stateful\_rule\_group) | Config for domain type stateful rule group | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    capacity    = number<br/>    domain_list = list(string)<br/>    actions     = string<br/>    protocols   = list(string)<br/>    rules_file  = optional(string, "")<br/>    rule_variables = optional(object({<br/>      ip_sets = list(object({<br/>        key    = string<br/>        ip_set = list(string)<br/>      }))<br/>      port_sets = list(object({<br/>        key       = string<br/>        port_sets = list(string)<br/>      }))<br/>      }), {<br/>      ip_sets   = []<br/>      port_sets = []<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_aws_nfw_fivetuple_stateful_rule_group"></a> [aws\_nfw\_fivetuple\_stateful\_rule\_group](#input\_aws\_nfw\_fivetuple\_stateful\_rule\_group) | Config for 5-tuple type stateful rule group | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    capacity    = number<br/>    rule_config = list(object({<br/>      description           = string<br/>      protocol              = string<br/>      source_ipaddress      = string<br/>      source_port           = string<br/>      direction             = string<br/>      destination_port      = string<br/>      destination_ipaddress = string<br/>      sid                   = number<br/>      actions               = map(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_aws_nfw_name"></a> [aws\_nfw\_name](#input\_aws\_nfw\_name) | AWS NFW Name | `string` | `""` | no |
| <a name="input_aws_nfw_prefix"></a> [aws\_nfw\_prefix](#input\_aws\_nfw\_prefix) | AWS NFW Prefix | `string` | `""` | no |
| <a name="input_aws_nfw_stateless_rule_group"></a> [aws\_nfw\_stateless\_rule\_group](#input\_aws\_nfw\_stateless\_rule\_group) | AWS NFW sateless rule group | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    capacity    = number<br/>    rule_config = list(object({<br/>      protocols_number      = list(number)<br/>      source_ipaddress      = string<br/>      source_to_port        = string<br/>      destination_to_port   = string<br/>      destination_ipaddress = string<br/>      tcp_flag = object({<br/>        flags = list(string)<br/>        masks = list(string)<br/>      })<br/>      actions = map(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_aws_nfw_suricata_stateful_rule_group"></a> [aws\_nfw\_suricata\_stateful\_rule\_group](#input\_aws\_nfw\_suricata\_stateful\_rule\_group) | Config for Suricata type stateful rule group | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    capacity    = number<br/>    rules_file  = optional(string, "")<br/>    rule_variables = optional(object({<br/>      ip_sets = list(object({<br/>        key    = string<br/>        ip_set = list(string)<br/>      }))<br/>      port_sets = list(object({<br/>        key       = string<br/>        port_sets = list(string)<br/>      }))<br/>      }), {<br/>      ip_sets   = []<br/>      port_sets = []<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | A list of availability zones in the region | `list(string)` | `[]` | no |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | The CIDR block for the VPC. | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | Customer KMS Key id for Cloudwatch Log encryption | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days to retain Cloudwatch logs | `number` | `365` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Controls if database subnet group should be created | `bool` | `true` | no |
| <a name="input_create_database_subnet_route_table"></a> [create\_database\_subnet\_route\_table](#input\_create\_database\_subnet\_route\_table) | Controls if separate route table for database should be created | `bool` | `false` | no |
| <a name="input_create_elasticache_subnet_route_table"></a> [create\_elasticache\_subnet\_route\_table](#input\_create\_elasticache\_subnet\_route\_table) | Controls if separate route table for elasticache should be created | `bool` | `false` | no |
| <a name="input_create_redshift_subnet_route_table"></a> [create\_redshift\_subnet\_route\_table](#input\_create\_redshift\_subnet\_route\_table) | Controls if separate route table for redshift should be created | `bool` | `false` | no |
| <a name="input_create_vpc_endpoints"></a> [create\_vpc\_endpoints](#input\_create\_vpc\_endpoints) | Whether to create VPC endpoints | `bool` | `false` | no |
| <a name="input_database_custom_routes"></a> [database\_custom\_routes](#input\_database\_custom\_routes) | Custom routes for Database Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    transit_gateway_id         = optional(string, null)<br/>    vpc_endpoint_id            = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_database_route_table_tags"></a> [database\_route\_table\_tags](#input\_database\_route\_table\_tags) | Additional tags for the database route tables | `map(string)` | `{}` | no |
| <a name="input_database_subnet_group_tags"></a> [database\_subnet\_group\_tags](#input\_database\_subnet\_group\_tags) | Additional tags for the database subnet group | `map(string)` | `{}` | no |
| <a name="input_database_subnet_suffix"></a> [database\_subnet\_suffix](#input\_database\_subnet\_suffix) | Suffix to append to database subnets name | `string` | `"db"` | no |
| <a name="input_database_subnet_tags"></a> [database\_subnet\_tags](#input\_database\_subnet\_tags) | Additional tags for the database subnets | `map(string)` | `{}` | no |
| <a name="input_database_subnets"></a> [database\_subnets](#input\_database\_subnets) | A list of database subnets | `map` | `{}` | no |
| <a name="input_default_vpc_enable_dns_hostnames"></a> [default\_vpc\_enable\_dns\_hostnames](#input\_default\_vpc\_enable\_dns\_hostnames) | Should be true to enable DNS hostnames in the Default VPC | `bool` | `false` | no |
| <a name="input_default_vpc_enable_dns_support"></a> [default\_vpc\_enable\_dns\_support](#input\_default\_vpc\_enable\_dns\_support) | Should be true to enable DNS support in the Default VPC | `bool` | `true` | no |
| <a name="input_default_vpc_name"></a> [default\_vpc\_name](#input\_default\_vpc\_name) | Name to be used on the Default VPC | `string` | `""` | no |
| <a name="input_default_vpc_tags"></a> [default\_vpc\_tags](#input\_default\_vpc\_tags) | Additional tags for the Default VPC | `map(string)` | `{}` | no |
| <a name="input_delete_protection"></a> [delete\_protection](#input\_delete\_protection) | Whether or not to enable deletion protection of NFW | `bool` | `true` | no |
| <a name="input_deploy_aws_nfw"></a> [deploy\_aws\_nfw](#input\_deploy\_aws\_nfw) | enable nfw true/false | `bool` | `false` | no |
| <a name="input_dhcp_options_domain_name"></a> [dhcp\_options\_domain\_name](#input\_dhcp\_options\_domain\_name) | Specifies DNS name for DHCP options set | `string` | `""` | no |
| <a name="input_dhcp_options_domain_name_servers"></a> [dhcp\_options\_domain\_name\_servers](#input\_dhcp\_options\_domain\_name\_servers) | Specify a list of DNS server addresses for DHCP options set, default to AWS provided | `list(string)` | <pre>[<br/>  "AmazonProvidedDNS"<br/>]</pre> | no |
| <a name="input_dhcp_options_netbios_name_servers"></a> [dhcp\_options\_netbios\_name\_servers](#input\_dhcp\_options\_netbios\_name\_servers) | Specify a list of netbios servers for DHCP options set | `list(string)` | `[]` | no |
| <a name="input_dhcp_options_netbios_node_type"></a> [dhcp\_options\_netbios\_node\_type](#input\_dhcp\_options\_netbios\_node\_type) | Specify netbios node\_type for DHCP options set | `string` | `""` | no |
| <a name="input_dhcp_options_ntp_servers"></a> [dhcp\_options\_ntp\_servers](#input\_dhcp\_options\_ntp\_servers) | Specify a list of NTP servers for DHCP options set | `list(string)` | `[]` | no |
| <a name="input_dhcp_options_tags"></a> [dhcp\_options\_tags](#input\_dhcp\_options\_tags) | Additional tags for the DHCP option set | `map(string)` | `{}` | no |
| <a name="input_elasticache_custom_routes"></a> [elasticache\_custom\_routes](#input\_elasticache\_custom\_routes) | Custom routes for Elasticache Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    transit_gateway_id         = optional(string, null)<br/>    vpc_endpoint_id            = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_elasticache_route_table_tags"></a> [elasticache\_route\_table\_tags](#input\_elasticache\_route\_table\_tags) | Additional tags for the elasticache route tables | `map(string)` | `{}` | no |
| <a name="input_elasticache_subnet_suffix"></a> [elasticache\_subnet\_suffix](#input\_elasticache\_subnet\_suffix) | Suffix to append to elasticache subnets name | `string` | `"elasticache"` | no |
| <a name="input_elasticache_subnet_tags"></a> [elasticache\_subnet\_tags](#input\_elasticache\_subnet\_tags) | Additional tags for the elasticache subnets | `map(string)` | `{}` | no |
| <a name="input_elasticache_subnets"></a> [elasticache\_subnets](#input\_elasticache\_subnets) | A list of elasticache subnets | `map` | `{}` | no |
| <a name="input_enable_dhcp_options"></a> [enable\_dhcp\_options](#input\_enable\_dhcp\_options) | Should be true if you want to specify a DHCP options set with a custom domain name, DNS servers, NTP servers, netbios servers, and/or netbios server type | `bool` | `false` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Should be true to enable DNS hostnames in the VPC | `bool` | `false` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Should be true to enable DNS support in the VPC | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Should be true if you want to provision NAT Gateways for each of your private networks | `bool` | `false` | no |
| <a name="input_enable_tls_inspection"></a> [enable\_tls\_inspection](#input\_enable\_tls\_inspection) | enable nfw tls inspection true/false. deploy\_aws\_nfw must be true to enable this | `bool` | `false` | no |
| <a name="input_enable_vpn_gateway"></a> [enable\_vpn\_gateway](#input\_enable\_vpn\_gateway) | Should be true if you want to create a new VPN Gateway resource and attach it to the VPC | `bool` | `false` | no |
| <a name="input_external_nat_ip_ids"></a> [external\_nat\_ip\_ids](#input\_external\_nat\_ip\_ids) | List of EIP IDs to be assigned to the NAT Gateways (used in combination with reuse\_nat\_ips) | `list(string)` | `[]` | no |
| <a name="input_firewall_custom_routes"></a> [firewall\_custom\_routes](#input\_firewall\_custom\_routes) | Custom routes for Firewall Subnets | `list(map(string))` | `[]` | no |
| <a name="input_firewall_route_table_tags"></a> [firewall\_route\_table\_tags](#input\_firewall\_route\_table\_tags) | Additional tags for the firewall route tables | `map(string)` | `{}` | no |
| <a name="input_firewall_subnet_name_tag"></a> [firewall\_subnet\_name\_tag](#input\_firewall\_subnet\_name\_tag) | Additional name tag for the firewall subnets | `map(string)` | `{}` | no |
| <a name="input_firewall_subnet_suffix"></a> [firewall\_subnet\_suffix](#input\_firewall\_subnet\_suffix) | Suffix to append to firewall subnets name | `string` | `"firewall"` | no |
| <a name="input_firewall_subnets"></a> [firewall\_subnets](#input\_firewall\_subnets) | A list of firewall subnets inside the VPC | `map` | `{}` | no |
| <a name="input_flow_log_destination_arn"></a> [flow\_log\_destination\_arn](#input\_flow\_log\_destination\_arn) | The ARN of the Cloudwatch log destination for Flow Logs | `string` | `null` | no |
| <a name="input_flow_log_destination_type"></a> [flow\_log\_destination\_type](#input\_flow\_log\_destination\_type) | Type of flow log destination. Can be s3 or cloud-watch-logs | `string` | n/a | yes |
| <a name="input_igw_tags"></a> [igw\_tags](#input\_igw\_tags) | Additional tags for the internet gateway | `map(string)` | `{}` | no |
| <a name="input_instance_tenancy"></a> [instance\_tenancy](#input\_instance\_tenancy) | A tenancy option for instances launched into the VPC | `string` | `"default"` | no |
| <a name="input_intra_custom_routes"></a> [intra\_custom\_routes](#input\_intra\_custom\_routes) | Custom routes for Intra Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    transit_gateway_id         = optional(string, null)<br/>    vpc_endpoint_id            = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_intra_route_table_tags"></a> [intra\_route\_table\_tags](#input\_intra\_route\_table\_tags) | Additional tags for the intra route tables | `map(string)` | `{}` | no |
| <a name="input_intra_subnet_tags"></a> [intra\_subnet\_tags](#input\_intra\_subnet\_tags) | Additional tags for the intra subnets | `map(string)` | `{}` | no |
| <a name="input_intra_subnets"></a> [intra\_subnets](#input\_intra\_subnets) | A list of intra subnets | `map` | `{}` | no |
| <a name="input_manage_default_vpc"></a> [manage\_default\_vpc](#input\_manage\_default\_vpc) | Should be true to adopt and manage Default VPC | `bool` | `false` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | Should be false if you do not want to auto-assign public IP on launch | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to be used on all the resources as identifier | `string` | `""` | no |
| <a name="input_nat_eip_tags"></a> [nat\_eip\_tags](#input\_nat\_eip\_tags) | Additional tags for the NAT EIP | `map(string)` | `{}` | no |
| <a name="input_nat_gateway_tags"></a> [nat\_gateway\_tags](#input\_nat\_gateway\_tags) | Additional tags for the NAT gateways | `map(string)` | `{}` | no |
| <a name="input_nfw_kms_key_id"></a> [nfw\_kms\_key\_id](#input\_nfw\_kms\_key\_id) | NFW KMS Key Id for encryption | `string` | `null` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs`. | `bool` | `false` | no |
| <a name="input_private_custom_routes"></a> [private\_custom\_routes](#input\_private\_custom\_routes) | Custom routes for Private Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    transit_gateway_id         = optional(string, null)<br/>    vpc_endpoint_id            = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_private_route_table_tags"></a> [private\_route\_table\_tags](#input\_private\_route\_table\_tags) | Additional tags for the private route tables | `map(string)` | `{}` | no |
| <a name="input_private_subnet_suffix"></a> [private\_subnet\_suffix](#input\_private\_subnet\_suffix) | Suffix to append to private subnets name | `string` | `"private"` | no |
| <a name="input_private_subnet_tags"></a> [private\_subnet\_tags](#input\_private\_subnet\_tags) | Additional tags for the private subnets | `map(string)` | `{}` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | A list of private subnets inside the VPC | `map` | `{}` | no |
| <a name="input_propagate_private_route_tables_vgw"></a> [propagate\_private\_route\_tables\_vgw](#input\_propagate\_private\_route\_tables\_vgw) | Should be true if you want route table propagation | `bool` | `false` | no |
| <a name="input_propagate_public_route_tables_vgw"></a> [propagate\_public\_route\_tables\_vgw](#input\_propagate\_public\_route\_tables\_vgw) | Should be true if you want route table propagation | `bool` | `false` | no |
| <a name="input_public_custom_routes"></a> [public\_custom\_routes](#input\_public\_custom\_routes) | Custom routes for Public Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    internet_route             = optional(bool, null)<br/>    transit_gateway_id         = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_public_route_table_tags"></a> [public\_route\_table\_tags](#input\_public\_route\_table\_tags) | Additional tags for the public route tables | `map(string)` | `{}` | no |
| <a name="input_public_subnet_suffix"></a> [public\_subnet\_suffix](#input\_public\_subnet\_suffix) | Suffix to append to public subnets name | `string` | `"public"` | no |
| <a name="input_public_subnet_tags"></a> [public\_subnet\_tags](#input\_public\_subnet\_tags) | Additional tags for the public subnets | `map(string)` | `{}` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of public subnets inside the VPC | `map` | `{}` | no |
| <a name="input_redshift_custom_routes"></a> [redshift\_custom\_routes](#input\_redshift\_custom\_routes) | Custom routes for Redshift Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    transit_gateway_id         = optional(string, null)<br/>    vpc_endpoint_id            = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_redshift_route_table_tags"></a> [redshift\_route\_table\_tags](#input\_redshift\_route\_table\_tags) | Additional tags for the redshift route tables | `map(string)` | `{}` | no |
| <a name="input_redshift_subnet_group_tags"></a> [redshift\_subnet\_group\_tags](#input\_redshift\_subnet\_group\_tags) | Additional tags for the redshift subnet group | `map(string)` | `{}` | no |
| <a name="input_redshift_subnet_suffix"></a> [redshift\_subnet\_suffix](#input\_redshift\_subnet\_suffix) | Suffix to append to redshift subnets name | `string` | `"redshift"` | no |
| <a name="input_redshift_subnet_tags"></a> [redshift\_subnet\_tags](#input\_redshift\_subnet\_tags) | Additional tags for the redshift subnets | `map(string)` | `{}` | no |
| <a name="input_redshift_subnets"></a> [redshift\_subnets](#input\_redshift\_subnets) | A list of redshift subnets | `map` | `{}` | no |
| <a name="input_reuse_nat_ips"></a> [reuse\_nat\_ips](#input\_reuse\_nat\_ips) | Should be true if you don't want EIPs to be created for your NAT Gateways and will instead pass them in via the 'external\_nat\_ip\_ids' variable | `bool` | `false` | no |
| <a name="input_secondary_cidr_blocks"></a> [secondary\_cidr\_blocks](#input\_secondary\_cidr\_blocks) | List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool | `list(string)` | `[]` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `bool` | `false` | no |
| <a name="input_subnet_az_mapping"></a> [subnet\_az\_mapping](#input\_subnet\_az\_mapping) | Optional explicit mapping of subnets to AZs - defaults to distributing across AZs | `map(string)` | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_tgw_custom_routes"></a> [tgw\_custom\_routes](#input\_tgw\_custom\_routes) | Custom routes for TGW Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    transit_gateway_id         = optional(string, null)<br/>    vpc_endpoint_id            = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_tgw_route_table_tags"></a> [tgw\_route\_table\_tags](#input\_tgw\_route\_table\_tags) | Additional tags for the tgw route tables | `map(string)` | `{}` | no |
| <a name="input_tgw_subnet_suffix"></a> [tgw\_subnet\_suffix](#input\_tgw\_subnet\_suffix) | Suffix to append to tgw subnets name | `string` | `"tgw"` | no |
| <a name="input_tgw_subnet_tags"></a> [tgw\_subnet\_tags](#input\_tgw\_subnet\_tags) | Additional tags for the tgw subnets | `map(string)` | `{}` | no |
| <a name="input_tgw_subnets"></a> [tgw\_subnets](#input\_tgw\_subnets) | A list of tgw subnets inside the VPC | `map` | `{}` | no |
| <a name="input_tls_cert_arn"></a> [tls\_cert\_arn](#input\_tls\_cert\_arn) | TLS Certificate ARN | `string` | `""` | no |
| <a name="input_tls_description"></a> [tls\_description](#input\_tls\_description) | Description for the TLS Inspection | `string` | `"TLS Oubound Inspection"` | no |
| <a name="input_tls_destination_cidrs"></a> [tls\_destination\_cidrs](#input\_tls\_destination\_cidrs) | Destination CIDRs for TLS Inspection | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_tls_destination_from_port"></a> [tls\_destination\_from\_port](#input\_tls\_destination\_from\_port) | Destination Port for TLS Inspection | `number` | `443` | no |
| <a name="input_tls_destination_to_port"></a> [tls\_destination\_to\_port](#input\_tls\_destination\_to\_port) | Destination Port for TLS Inspection | `number` | `443` | no |
| <a name="input_tls_source_cidr"></a> [tls\_source\_cidr](#input\_tls\_source\_cidr) | Source CIDR for TLS Inspection | `string` | `"0.0.0.0/0"` | no |
| <a name="input_tls_source_from_port"></a> [tls\_source\_from\_port](#input\_tls\_source\_from\_port) | Source Port for TLS Inspection | `number` | `0` | no |
| <a name="input_tls_source_to_port"></a> [tls\_source\_to\_port](#input\_tls\_source\_to\_port) | Source Port for TLS Inspection | `number` | `65535` | no |
| <a name="input_vpc_endpoint_security_groups"></a> [vpc\_endpoint\_security\_groups](#input\_vpc\_endpoint\_security\_groups) | Map of security groups to create for VPC endpoints | <pre>map(object({<br/>    name        = string<br/>    description = optional(string, "Security group for VPC endpoint")<br/>    ingress_rules = optional(list(object({<br/>      description      = optional(string)<br/>      from_port        = number<br/>      to_port          = number<br/>      protocol         = string<br/>      cidr_blocks      = optional(list(string), [])<br/>      ipv6_cidr_blocks = optional(list(string), [])<br/>      security_groups  = optional(list(string), [])<br/>      self             = optional(bool, false)<br/>    })), [])<br/>    egress_rules = optional(list(object({<br/>      description      = optional(string)<br/>      from_port        = number<br/>      to_port          = number<br/>      protocol         = string<br/>      cidr_blocks      = optional(list(string), [])<br/>      ipv6_cidr_blocks = optional(list(string), [])<br/>      security_groups  = optional(list(string), [])<br/>      self             = optional(bool, false)<br/>    })), [])<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_endpoints"></a> [vpc\_endpoints](#input\_vpc\_endpoints) | Map of VPC endpoint definitions to create | <pre>map(object({<br/>    service_name        = optional(string)       # If not provided, standard AWS service name will be constructed<br/>    service_type        = string                 # "Interface", "Gateway", or "GatewayLoadBalancer"<br/>    private_dns_enabled = optional(bool, true)   # Only applicable for Interface endpoints<br/>    auto_accept         = optional(bool, false)<br/>    policy              = optional(string)       # JSON policy document<br/>    security_group_ids  = optional(list(string), [])<br/>    tags                = optional(map(string), {})<br/>    subnet_ids          = optional(list(string)) # Override default subnet_ids if needed<br/>    # Required only for GatewayLoadBalancer endpoints<br/>    ip_address_type     = optional(string)       # "ipv4" or "dualstack"<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | Additional tags for the VPC | `map(string)` | `{}` | no |
| <a name="input_vpn_gateway_id"></a> [vpn\_gateway\_id](#input\_vpn\_gateway\_id) | ID of VPN Gateway to attach to the VPC | `string` | `""` | no |
| <a name="input_vpn_gateway_tags"></a> [vpn\_gateway\_tags](#input\_vpn\_gateway\_tags) | Additional tags for the VPN gateway | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_nfw_endpoint_ids"></a> [aws\_nfw\_endpoint\_ids](#output\_aws\_nfw\_endpoint\_ids) | List of IDs of AWS NFW endpoints |
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
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | List of IDs of private route tables - including database route table IDs, as the database uses the private route tables |
| <a name="output_private_subnets"></a> [private\_subnets](#output\_private\_subnets) | List of IDs of private subnets |
| <a name="output_private_subnets_cidr_blocks"></a> [private\_subnets\_cidr\_blocks](#output\_private\_subnets\_cidr\_blocks) | List of cidr\_blocks of private subnets |
| <a name="output_public_route_table_ids"></a> [public\_route\_table\_ids](#output\_public\_route\_table\_ids) | List of IDs of public route tables |
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
| <a name="output_vpc_endpoint_security_groups"></a> [vpc\_endpoint\_security\_groups](#output\_vpc\_endpoint\_security\_groups) | Map of security group IDs created for VPC endpoints |
| <a name="output_vpc_endpoints"></a> [vpc\_endpoints](#output\_vpc\_endpoints) | Map of VPC endpoint IDs |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the VPC |
| <a name="output_vpc_instance_tenancy"></a> [vpc\_instance\_tenancy](#output\_vpc\_instance\_tenancy) | Tenancy of instances spin up within VPC |
| <a name="output_vpc_main_route_table_id"></a> [vpc\_main\_route\_table\_id](#output\_vpc\_main\_route\_table\_id) | The ID of the main route table associated with this VPC |
| <a name="output_vpc_secondary_cidr_blocks"></a> [vpc\_secondary\_cidr\_blocks](#output\_vpc\_secondary\_cidr\_blocks) | List of secondary CIDR blocks of the VPC |
<!-- END_TF_DOCS -->
