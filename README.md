==> README.md <==
![Coalfire](coalfire_logo.png)

# AWS VPC NFW Terraform Module

Terraform module which creates VPC and/or NFW resources on AWS.

These types of resources are supported:

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

## Submodule
[Network Firewall](modules/aws-network-firewall/README.md)

## Assumptions

* Networking resources, including VPCs, Transit Gateways and Network Firewalls, are designed to be deployed under a single state.
* Outputs of this module can be referenced via terraform state in the following manner:
  * `module.mgmt_vpc.private_subnets["mvp-mgmt-compute-us-gov-west-1a"]`
  * `data.terraform_remote_state.network.outputs.public_subnets["mvp-mgmt-dmz-us-gov-west-1a"]`
* This is designed to automatically reference the firewall subnets when opted to be created.
* Automatically adds AWS region to the subnet name upon creation
* The private route table IDs includes the rtb IDs from database subnets as well

## Usage
If networks are being created with the goal of peering, it is best practice to build and deploy those resources within the same Terraform state.
This allows for efficient referencing of peer subnets and CIDRs to facilitate a proper routing architecture. 
```hcl
module "mgmt_vpc" {
  source = "github.com/Coalfire-CF/terraform-aws-vpc-nfw"
  providers = {
    aws = aws.mgmt
  }

  name = "${var.resource_prefix}-mgmt"

  delete_protection = var.delete_protection

  cidr = var.mgmt_vpc_cidr

  azs = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]

  private_subnets = local.private_subnets # Map of Name -> CIDR

  public_subnets       = local.public_subnets # Map of Name -> CIDR
  public_subnet_suffix = "public"

  single_nat_gateway     = false
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true

  flow_log_destination_type              = "cloud-watch-logs"
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_kms_key_id        = data.terraform_remote_state.day0.outputs.cloudwatch_kms_key_arn

  ### Network Firewall ###
  deploy_aws_nfw                        = var.deploy_aws_nfw
  aws_nfw_prefix                        = var.resource_prefix
  aws_nfw_name                          = "pak-nfw"
  aws_nfw_stateless_rule_group          = local.stateless_rule_group_shrd_svcs
  aws_nfw_fivetuple_stateful_rule_group = local.fivetuple_rule_group_shrd_svcs
  aws_nfw_domain_stateful_rule_group    = local.domain_stateful_rule_group_shrd_svcs
  aws_nfw_suricata_stateful_rule_group  = local.suricata_rule_group_shrd_svcs # Requires creation of local file with fw rules
  nfw_kms_key_id                        = module.nfw_kms_key.kms_key_arn

  #When deploying NFW, firewall_subnets must be specified
  firewall_subnets       = local.firewall_subnets
  firewall_subnet_suffix = "firewall"

  # TLS Outbound Inspection
  enable_tls_inspection = var.enable_tls_inspection # deploy_aws_nfw must be set to true to enable this
  tls_cert_arn          = var.tls_cert_arn
  tls_destination_cidrs = var.tls_destination_cidrs # Set these to the NAT gateways to filter outbound traffic without affecting the hosted VPN

  /* Add Additional tags here */
  tags = {
    Owner       = var.resource_prefix
    Environment = "mgmt"
    createdBy   = "terraform"
  }
}
```
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


## AWS Networking deployment without AWS Network Firewall
```hcl
module "mgmt_vpc" {
  source = "github.com/Coalfire-CF/terraform-aws-vpc-nfw"
  providers = {
    aws = aws.mgmt
  }

  name = "${var.resource_prefix}-mgmt"

  delete_protection = var.delete_protection

  cidr = var.mgmt_vpc_cidr

  azs = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]

  private_subnets = local.private_subnets # Map of Name -> CIDR

  public_subnets       = local.public_subnets # Map of Name -> CIDR
  public_subnet_suffix = "public"

  single_nat_gateway     = false
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true

  flow_log_destination_type              = "cloud-watch-logs"
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_kms_key_id        = data.terraform_remote_state.day0.outputs.cloudwatch_kms_key_arn

  /* Add Additional tags here */
  tags = {
    Owner       = var.resource_prefix
    Environment = "mgmt"
    createdBy   = "terraform"
  }
}
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

## Tree
## Tree
```
.
|-- [CONTRIBUTING.md](./CONTRIBUTING.md)
|-- [LICENSE](./LICENSE)
|-- [README.md](./README.md)
|-- [coalfire_logo.png](./coalfire_logo.png)
|-- [endpoints.tf](./endpoints.tf)
|-- [example](./example)
|   `-- [example/vpc-nfw](./example/vpc-nfw)
|    |-- [example/vpc-nfw/README.md](./example/vpc-nfw/README.md)
|    |-- [example/vpc-nfw/data.tf](./example/vpc-nfw/data.tf)
|    |-- [example/vpc-nfw/kms.tf](./example/vpc-nfw/kms.tf)
|    |-- [example/vpc-nfw/locals.tf](./example/vpc-nfw/locals.tf)
|    |-- [example/vpc-nfw/mgmt.tf](./example/vpc-nfw/mgmt.tf)
|    |-- [example/vpc-nfw/nfw_policies.tf](./example/vpc-nfw/nfw_policies.tf)
|    |-- [example/vpc-nfw/outputs.tf](./example/vpc-nfw/outputs.tf)
|    |-- [example/vpc-nfw/providers.tf](./example/vpc-nfw/providers.tf)
|    |-- [example/vpc-nfw/required_providers.tf](./example/vpc-nfw/required_providers.tf)
|    |-- [example/vpc-nfw/subnets.tf](./example/vpc-nfw/subnets.tf)
|    |-- [example/vpc-nfw/test.rules.json](./example/vpc-nfw/test.rules.json)
|    |-- [example/vpc-nfw/tstate.tf](./example/vpc-nfw/tstate.tf)
|    |-- [example/vpc-nfw/variables.tf](./example/vpc-nfw/variables.tf)
|    `-- [example/vpc-nfw/vars.auto.tfvars](./example/vpc-nfw/vars.auto.tfvars)
|-- [flowlog.tf](./flowlog.tf)
|-- [main.tf](./main.tf)
|-- [modules](./modules)
|   `-- [modules/aws-network-firewall](./modules/aws-network-firewall)
|    |-- [modules/aws-network-firewall/README.md](./modules/aws-network-firewall/README.md)
|    |-- [modules/aws-network-firewall/coalfire_logo.png](./modules/aws-network-firewall/coalfire_logo.png)
|    |-- [modules/aws-network-firewall/locals.tf](./modules/aws-network-firewall/locals.tf)
|    |-- [modules/aws-network-firewall/main.tf](./modules/aws-network-firewall/main.tf)
|    |-- [modules/aws-network-firewall/nfw-base-suricata-rules.json](./modules/aws-network-firewall/nfw-base-suricata-rules.json)
|    |-- [modules/aws-network-firewall/output.tf](./modules/aws-network-firewall/output.tf)
|    |-- [modules/aws-network-firewall/required_providers.tf](./modules/aws-network-firewall/required_providers.tf)
|    |-- [modules/aws-network-firewall/tls.tf](./modules/aws-network-firewall/tls.tf)
|    `-- [modules/aws-network-firewall/variables.tf](./modules/aws-network-firewall/variables.tf)
|-- [outputs.tf](./outputs.tf)
|-- [required_providers.tf](./required_providers.tf)
|-- [routes.tf](./routes.tf)
|-- [subnets.tf](./subnets.tf)
|-- [variables.tf](./variables.tf)
`-- [update-readme-tree.sh](./update-readme-tree.sh)
```
