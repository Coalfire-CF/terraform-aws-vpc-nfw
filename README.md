![Coalfire](coalfire_logo.png)

# terraform-aws-vpc-nfw

## Description

Terraform module which creates VPC (and optionally NFW) resources on AWS.

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
* AWS region is appended to the subnet name by default.
* The private route table IDs includes the route table IDs from database subnets as well.

# Usage
For a detailed example of module usage and structure, see the `example/vpc-nfw` folder.

A simplified module call is given below to demonstrate general format/syntax and structure:

```hcl
module "mgmt_vpc" {
  source = "git::https://github.com/Coalfire-CF/terraform-aws-vpc-nfw.git?ref=vx.x.x"
  name = "example-mgmt"
  cidr = "x.x.x.x/xx"
  azs  = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]

  subnets = [
    {
      tag               = "subnet1"
      cidr              = "10.0.0.0/24"
      type              = "firewall"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "subnet2"
      cidr              = "10.0.1.0/24"
      type              = "public"
      availability_zone = "us-gov-west-1b"
    }
  ]

  single_nat_gateway     = false
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true

  flow_log_destination_type              = "cloud-watch-logs"
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_kms_key_id        = "arn:aws-us-gov:kms:your-cloudwatch-kms-key-arn"

  deploy_aws_nfw                        = true
  delete_protection                     = true
  aws_nfw_prefix                        = "example"
  aws_nfw_name                          = "example-nfw"
  aws_nfw_fivetuple_stateful_rule_group = local.fivetuple_rule_group
  aws_nfw_suricata_stateful_rule_group  = local.suricata_rule_group_shrd_svcs
  nfw_kms_key_arn                        = "arn:aws-us-gov:kms:your-nfw-kms-key-arn"
}
```

### EKS Subnet Tagging

When deploying EKS clusters, specific subnets need Kubernetes and AWS service discovery tags for the AWS Load Balancer Controller, Karpenter, and other integrations. Use the `eks` flag on individual subnets to selectively apply these tags without affecting other subnets in the VPC.

The following tags are applied based on configuration:

| Tag | Applied To | Purpose | Controlled By |
|---|---|---|---|
| `kubernetes.io/cluster/<cluster-name>` | Private + Public subnets with `eks = true` | Cluster ownership | `enable_eks_subnet_tagging`, `eks_cluster_name` |
| `kubernetes.io/role/internal-elb` | Private subnets with `eks = true` | Internal ALB/NLB discovery | `enable_eks_private_subnet_tags` |
| `kubernetes.io/role/elb` | Public subnets with `eks = true` | Internet-facing ALB/NLB discovery | `enable_eks_public_subnet_tags` |
| `karpenter.sh/discovery` | Private subnets with `eks = true` | Karpenter node provisioning | `enable_karpenter_subnet_tags` |

> It is recommended to deploy EKS subnets across 3 Availability Zones for high availability.

```hcl
module "eks_vpc" {
  source = "git::https://github.com/Coalfire-CF/terraform-aws-vpc-nfw.git?ref=vx.x.x"

  vpc_name        = "eks-vpc"
  resource_prefix = "prod"
  cidr            = "10.10.0.0/16"
  azs             = ["us-gov-west-1a", "us-gov-west-1b", "us-gov-west-1c"]

  # Enable EKS subnet tagging
  enable_eks_subnet_tagging    = true
  eks_cluster_name             = "prod-eks-cluster"
  eks_cluster_tag_value        = "shared"  # "shared" if multiple clusters use these subnets, "owned" if dedicated
  enable_karpenter_subnet_tags = true      # Adds karpenter.sh/discovery to private EKS subnets

  subnets = [
    # Firewall subnets (no EKS tags)
    {
      tag               = "firewall"
      cidr              = "10.10.0.0/28"
      type              = "firewall"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "firewall"
      cidr              = "10.10.0.16/28"
      type              = "firewall"
      availability_zone = "us-gov-west-1b"
    },
    {
      tag               = "firewall"
      cidr              = "10.10.0.32/28"
      type              = "firewall"
      availability_zone = "us-gov-west-1c"
    },

    # Public subnets for EKS load balancers (tagged with kubernetes.io/role/elb)
    {
      tag               = "eks-public"
      cidr              = "10.10.1.0/24"
      type              = "public"
      availability_zone = "us-gov-west-1a"
      eks               = true
    },
    {
      tag               = "eks-public"
      cidr              = "10.10.2.0/24"
      type              = "public"
      availability_zone = "us-gov-west-1b"
      eks               = true
    },
    {
      tag               = "eks-public"
      cidr              = "10.10.3.0/24"
      type              = "public"
      availability_zone = "us-gov-west-1c"
      eks               = true
    },

    # Public subnets NOT for EKS (no EKS tags applied)
    {
      tag               = "dmz"
      cidr              = "10.10.4.0/24"
      type              = "public"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "dmz"
      cidr              = "10.10.5.0/24"
      type              = "public"
      availability_zone = "us-gov-west-1b"
    },
    {
      tag               = "dmz"
      cidr              = "10.10.6.0/24"
      type              = "public"
      availability_zone = "us-gov-west-1c"
    },

    # Private subnets for EKS workloads (tagged with internal-elb + karpenter)
    {
      tag               = "eks-private"
      cidr              = "10.10.10.0/24"
      type              = "private"
      availability_zone = "us-gov-west-1a"
      eks               = true
    },
    {
      tag               = "eks-private"
      cidr              = "10.10.11.0/24"
      type              = "private"
      availability_zone = "us-gov-west-1b"
      eks               = true
    },
    {
      tag               = "eks-private"
      cidr              = "10.10.12.0/24"
      type              = "private"
      availability_zone = "us-gov-west-1c"
      eks               = true
    },

    # Private subnets for other workloads (no EKS tags applied)
    {
      tag               = "app"
      cidr              = "10.10.20.0/24"
      type              = "private"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "app"
      cidr              = "10.10.21.0/24"
      type              = "private"
      availability_zone = "us-gov-west-1b"
    },
    {
      tag               = "app"
      cidr              = "10.10.22.0/24"
      type              = "private"
      availability_zone = "us-gov-west-1c"
    },
  ]

  single_nat_gateway     = false
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_dns_hostnames   = true

  flow_log_destination_type              = "cloud-watch-logs"
  cloudwatch_log_group_retention_in_days = 30
}
```

| EKS Tagging Variable | Description | Default |
|---|---|---|
| `enable_eks_subnet_tagging` | Master toggle for all EKS tags | `false` |
| `eks_cluster_name` | EKS cluster name used in tag keys/values | `""` |
| `eks_cluster_tag_value` | `"shared"` or `"owned"` for the cluster ownership tag | `"shared"` |
| `enable_eks_private_subnet_tags` | Apply `kubernetes.io/role/internal-elb` to private EKS subnets | `true` |
| `enable_eks_public_subnet_tags` | Apply `kubernetes.io/role/elb` to public EKS subnets | `true` |
| `enable_karpenter_subnet_tags` | Apply `karpenter.sh/discovery` to private EKS subnets | `false` |
| `karpenter_discovery_tag_value` | Custom value for Karpenter tag (defaults to `eks_cluster_name`) | `""` |

> Note: If networks are being created with the goal of peering, it is best practice to build and deploy those resources within the same Terraform state. This allows for efficient referencing of peer subnets and CIDRs to facilitate a proper routing architecture. Please refer to the 'example' folder for example files needed on the parent module calling this PAK based on the deployment requirements.

## Inputs

| Input | Description | Example |
|---|---|---|
| resource_prefix | Deployment-wide identifier prepended to resource names (excluding any explicitly-defined or custom resource names) | `"prod"` |
| vpc_name | Name to assign to the VPC resource | `"mgmt-prod-vpc"` |
| cidr | The CIDR block to assign to the VPC. See the [AWS User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html) for more info on defining VPC CIDRs. | `"10.0.0.0/16"` |
| azs | This variable defines the Availability Zones in your environment. You may use a terraform `data` call to retrieve these values dynamically from the AWS provider. | `[data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]` |
| subnets | A block of subnet definitions. | See [subnets](#defining-the-subnets-block) |
| enable_nat_gateway | Whether to deploy NAT gateway(s) | `true` |
| single_nat_gateway | If `true`, only deploys a single NAT gateway, shared between all private subnets | `false` |
| one_nat_gateway_per_az | If `true`, deploys only one NAT gateway per Availability Zone, shared between all private subnets in that AZ | `true` |
| enable_vpn_gateway | If `true`, creates a VPN gateway resource attached to the VPC | `false` |
| vpn_gateway_custom_name | (Optional) If set, this replaces the default generated name of the AWS VPN with the provided value  | `"mgmt-prod-vpn"` |
| enable_dns_hostnames | If `true`, enables DNS hostnames in the Default VPC | `false` |
| flow_log_destination_type | The type of flow log destination. msut be one of `"s3"` or `"cloud-watch-logs"` | `"cloud-watch-logs"` |
| cloudwatch_log_group_retention_in_days | The length of time, in days, to retain CloudWatch logs | `30`|
| cloudwatch_log_group_kms_key_arn | ARN of the KMS key to use for the cloudwatch log group encryption. | `"arn:aws-us-gov:kms:your-kms-key-arn"` |
| deploy_aws_nfw | If `true`, deploys AWS Network Firewall | `true` | 
| delete_protection | If `true`, prevents deletion of the AWS Network Firewall. | `true` |
| aws_nfw_name | Name to assign to the NFW resource | `"mgmt-prod-nfw"` |
| aws_nfw_fivetuple_stateful_rule_group | Object block containing config for Suricata 5-tuple type stateful rule group | See [Replacing the Default Deny All NFW Policy](#replacing-the-default-deny-all-nfw-policy) | 
| aws_nfw_suricata_stateful_rule_group | Object block containing config for Suricata type stateful rule group| See [Replacing the Default Deny All NFW Policy](#replacing-the-default-deny-all-nfw-policy) | 
| nfw_kms_key_arn | ARN of the KMS key to use for firewall encryption | `"arn:aws-us-gov:kms:your-kms-key-arn"` |

### Defining the subnets block
Subnets are specified via the `subnets` block:

```hcl
  subnets = [
    {
      tag               = "fw1"  
      cidr              = "10.0.0.0/24"
      type              = "firewall"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "fw2"  
      cidr              = "10.0.1.0/24"
      type              = "firewall"
      availability_zone = "us-gov-west-1b"
    }
  ]
```

Each subnet must be defined with the following Attributes:

| Attribute | Description | Example |
|---|---|---|
| tag | An arbitrary identifier (freindly name) which will be combined with `resource_prefix` variable and the subnet's `availability_zone` to form the subnet `Name` tag. For example, for a deployment with `resource_prefix` "example", setting `tag = "secops"` and `availability_zone = us-gov-west-1a` will result in the subnet name `example-secops-us-gov-west-1a` | `siem` |
| cidr | Defines the CIDR block for the subnet. Subnet CIDR blocks must not overlap, and no two subnets can have the same CIDR block. See the [AWS User Guide](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-sizing.html) for more information on defining CIDR blocks for VPC subnets. | `10.0.3.0/24` |
| type | Determines the type of subnet to deploy. Allowed values are `firewall`, `public`, `private`, `tgw`, `database`, `redshift`, `elasticache`, or `intra` | `private` | 
| availability_zone | The availability zone in which to create the subnet. The AZ specified here must be available in your environment. | `us-gov-west-1b` |
| custom_name | (Optional, supersedes `tag`) If your environment has strict requirements for resource naming, you may specify `custom_name` in place of `tag` to define the exact string to assign to the subnet's Name tag. | `aws-subnet-private-secops-west-1a` |
| eks | (Optional) If `true`, applies EKS-related tags to this subnet when `enable_eks_subnet_tagging` is enabled. Only valid on `private` or `public` subnet types. Defaults to `false`. | `true` |

> Note: You may specify any number of subnets, in any order, and of any combination of types, availability zones, and CIDR blocks. Note that you may arbitrarily destroy or create subnets as the need arises, without affecting other subnets. (Always check the output of `terraform plan` before applying changes)

### (Optional) Defining subnet CIDRs using Hashicorp CIDR module
If desired, you may define subnet CIDRs dynamically using Hashicorp's [Terraform CIDR Subnets Module](https://registry.terraform.io/modules/hashicorp/subnets/cidr/latest):

```hcl
module "cidr_blocks" {
  source          = "hashicorp/subnets/cidr"
  version         = "v1.0.0"
  base_cidr_block = var.mgmt_vpc_cidr
  networks = [
    {
      name     = "block1"
      new_bits = 8
    },
    {
      name     = "block2"
      new_bits = 8
    }
  ]
}

module "mgmt_vpc" {
  cidr = var.mgmt_vpc_cidr
  ...
  subnets = [
    {
      tag               = "firewall1"
      cidr              = module.cidr_blocks.network_cidr_blocks["block1"]
      type              = "firewall"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "firewall1"
      cidr              = module.cidr_blocks.network_cidr_blocks["block2"]
      type              = "firewall"
      availability_zone = "us-gov-west-1b"
    }
  ]
  ...
}
```

> ⚠️ **WARNING:** due to the way the module Hashicorp subnetting module generates CIDRs, it is likely that removing, adding, or otherwise changing one subnet in the module can cause all other subnet CIDRs to be updated, potentially generating cascading effects across your deployment. If using this method, it is highly recommended to define all subnets during your first deployment, and excercise extreme caution when making any updates. 


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

These deployments steps assume you will be deploying this PAK (including AWS NFW) on the Management plane VPC. 

**NOTE: Please use the code under the 'Usage' section on this README for the most up-to-date code while referring to the 'example' folder for previous deployment examples only.**

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
3. Review and update 'nfw_policies.tf', 'subnets.tf', and 'suricata.json' if needed.

4. Initialize the Terraform working directory:
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

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
| [aws_flow_log.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
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
| [aws_route53_resolver_dnssec_config.vpc_resolver_dnssec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_resolver_dnssec_config) | resource |
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
| [aws_s3_bucket.flowlogs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_logging.flowlogs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_policy.flowlogs_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.flowlogs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.flowlogs-encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
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
| [aws_iam_policy_document.flowlogs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.vpc_flow_log_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_assign_generated_ipv6_cidr_block"></a> [assign\_generated\_ipv6\_cidr\_block](#input\_assign\_generated\_ipv6\_cidr\_block) | Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block | `bool` | `false` | no |
| <a name="input_associate_with_private_route_tables"></a> [associate\_with\_private\_route\_tables](#input\_associate\_with\_private\_route\_tables) | Whether to associate Gateway endpoints with private route tables | `bool` | `true` | no |
| <a name="input_associate_with_public_route_tables"></a> [associate\_with\_public\_route\_tables](#input\_associate\_with\_public\_route\_tables) | Whether to associate Gateway endpoints with public route tables | `bool` | `false` | no |
| <a name="input_aws_nfw_domain_stateful_rule_group"></a> [aws\_nfw\_domain\_stateful\_rule\_group](#input\_aws\_nfw\_domain\_stateful\_rule\_group) | Config for domain type stateful rule group | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    capacity    = number<br/>    domain_list = list(string)<br/>    actions     = string<br/>    protocols   = list(string)<br/>    rules_file  = optional(string, "")<br/>    rule_variables = optional(object({<br/>      ip_sets = list(object({<br/>        key    = string<br/>        ip_set = list(string)<br/>      }))<br/>      port_sets = list(object({<br/>        key       = string<br/>        port_sets = list(string)<br/>      }))<br/>      }), {<br/>      ip_sets   = []<br/>      port_sets = []<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_aws_nfw_fivetuple_stateful_rule_group"></a> [aws\_nfw\_fivetuple\_stateful\_rule\_group](#input\_aws\_nfw\_fivetuple\_stateful\_rule\_group) | Config for 5-tuple type stateful rule group | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    capacity    = number<br/>    rule_config = list(object({<br/>      description           = string<br/>      protocol              = string<br/>      source_ipaddress      = string<br/>      source_port           = string<br/>      direction             = string<br/>      destination_port      = string<br/>      destination_ipaddress = string<br/>      sid                   = number<br/>      actions               = map(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_aws_nfw_name"></a> [aws\_nfw\_name](#input\_aws\_nfw\_name) | AWS NFW Name | `string` | `""` | no |
| <a name="input_aws_nfw_stateless_rule_group"></a> [aws\_nfw\_stateless\_rule\_group](#input\_aws\_nfw\_stateless\_rule\_group) | AWS NFW sateless rule group | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    capacity    = number<br/>    rule_config = list(object({<br/>      protocols_number      = list(number)<br/>      source_ipaddress      = string<br/>      source_to_port        = string<br/>      destination_to_port   = string<br/>      destination_ipaddress = string<br/>      tcp_flag = object({<br/>        flags = list(string)<br/>        masks = list(string)<br/>      })<br/>      actions = map(string)<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_aws_nfw_suricata_stateful_rule_group"></a> [aws\_nfw\_suricata\_stateful\_rule\_group](#input\_aws\_nfw\_suricata\_stateful\_rule\_group) | Config for Suricata type stateful rule group | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    capacity    = number<br/>    rules_file  = optional(string, "")<br/>    rule_variables = optional(object({<br/>      ip_sets = list(object({<br/>        key    = string<br/>        ip_set = list(string)<br/>      }))<br/>      port_sets = list(object({<br/>        key       = string<br/>        port_sets = list(string)<br/>      }))<br/>      }), {<br/>      ip_sets   = []<br/>      port_sets = []<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | A list of availability zones in the region | `list(string)` | `[]` | no |
| <a name="input_cidr"></a> [cidr](#input\_cidr) | The CIDR block for the VPC. | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_kms_key_arn"></a> [cloudwatch\_log\_group\_kms\_key\_arn](#input\_cloudwatch\_log\_group\_kms\_key\_arn) | Customer KMS Key ARN for Cloudwatch Log encryption | `string` | `""` | no |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days to retain Cloudwatch logs | `number` | `365` | no |
| <a name="input_create_database_subnet_group"></a> [create\_database\_subnet\_group](#input\_create\_database\_subnet\_group) | Controls if database subnet group should be created | `bool` | `true` | no |
| <a name="input_create_database_subnet_route_table"></a> [create\_database\_subnet\_route\_table](#input\_create\_database\_subnet\_route\_table) | Controls if separate route table for database should be created | `bool` | `false` | no |
| <a name="input_create_elasticache_subnet_route_table"></a> [create\_elasticache\_subnet\_route\_table](#input\_create\_elasticache\_subnet\_route\_table) | Controls if separate route table for elasticache should be created | `bool` | `false` | no |
| <a name="input_create_redshift_subnet_route_table"></a> [create\_redshift\_subnet\_route\_table](#input\_create\_redshift\_subnet\_route\_table) | Controls if separate route table for redshift should be created | `bool` | `false` | no |
| <a name="input_create_vpc_endpoints"></a> [create\_vpc\_endpoints](#input\_create\_vpc\_endpoints) | Whether to create VPC endpoints | `bool` | `false` | no |
| <a name="input_database_custom_routes"></a> [database\_custom\_routes](#input\_database\_custom\_routes) | Custom routes for Database Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    transit_gateway_id         = optional(string, null)<br/>    vpc_endpoint_id            = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_database_route_table_tags"></a> [database\_route\_table\_tags](#input\_database\_route\_table\_tags) | Additional tags for the database route tables | `map(string)` | `{}` | no |
| <a name="input_database_subnet_group_name"></a> [database\_subnet\_group\_name](#input\_database\_subnet\_group\_name) | Optional custom resource name for the database subnet group | `string` | `null` | no |
| <a name="input_database_subnet_group_tags"></a> [database\_subnet\_group\_tags](#input\_database\_subnet\_group\_tags) | Additional tags for the database subnet group | `map(string)` | `{}` | no |
| <a name="input_database_subnet_tags"></a> [database\_subnet\_tags](#input\_database\_subnet\_tags) | Additional tags for the database subnets | `map(string)` | `{}` | no |
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
| <a name="input_eks_cluster_name"></a> [eks\_cluster\_name](#input\_eks\_cluster\_name) | Name of the EKS cluster (used for kubernetes.io/cluster/<name> and karpenter.sh/discovery tags) | `string` | `""` | no |
| <a name="input_eks_cluster_tag_value"></a> [eks\_cluster\_tag\_value](#input\_eks\_cluster\_tag\_value) | Value for the kubernetes.io/cluster/<name> tag. Use 'shared' if subnets are shared across clusters, 'owned' if dedicated. | `string` | `"shared"` | no |
| <a name="input_elasticache_custom_routes"></a> [elasticache\_custom\_routes](#input\_elasticache\_custom\_routes) | Custom routes for Elasticache Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    transit_gateway_id         = optional(string, null)<br/>    vpc_endpoint_id            = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_elasticache_route_table_tags"></a> [elasticache\_route\_table\_tags](#input\_elasticache\_route\_table\_tags) | Additional tags for the elasticache route tables | `map(string)` | `{}` | no |
| <a name="input_elasticache_subnet_group_name"></a> [elasticache\_subnet\_group\_name](#input\_elasticache\_subnet\_group\_name) | Optional custom resource name for the Elasticache subnet group | `string` | `null` | no |
| <a name="input_elasticache_subnet_tags"></a> [elasticache\_subnet\_tags](#input\_elasticache\_subnet\_tags) | Additional tags for the elasticache subnets | `map(string)` | `{}` | no |
| <a name="input_enable_dhcp_options"></a> [enable\_dhcp\_options](#input\_enable\_dhcp\_options) | Should be true if you want to specify a DHCP options set with a custom domain name, DNS servers, NTP servers, netbios servers, and/or netbios server type | `bool` | `false` | no |
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Should be true to enable DNS hostnames in the VPC | `bool` | `false` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Should be true to enable DNS support in the VPC | `bool` | `true` | no |
| <a name="input_enable_eks_private_subnet_tags"></a> [enable\_eks\_private\_subnet\_tags](#input\_enable\_eks\_private\_subnet\_tags) | Enable kubernetes.io/role/internal-elb tag on private subnets for AWS Load Balancer Controller | `bool` | `true` | no |
| <a name="input_enable_eks_public_subnet_tags"></a> [enable\_eks\_public\_subnet\_tags](#input\_enable\_eks\_public\_subnet\_tags) | Enable kubernetes.io/role/elb tag on public subnets for AWS Load Balancer Controller | `bool` | `true` | no |
| <a name="input_enable_eks_subnet_tagging"></a> [enable\_eks\_subnet\_tagging](#input\_enable\_eks\_subnet\_tagging) | Enable EKS-related subnet tagging via aws\_ec2\_tag resources | `bool` | `false` | no |
| <a name="input_enable_karpenter_subnet_tags"></a> [enable\_karpenter\_subnet\_tags](#input\_enable\_karpenter\_subnet\_tags) | Enable karpenter.sh/discovery tag on private subnets for Karpenter node provisioning | `bool` | `false` | no |
| <a name="input_enable_nat_gateway"></a> [enable\_nat\_gateway](#input\_enable\_nat\_gateway) | Should be true if you want to provision NAT Gateways for each of your private networks | `bool` | `false` | no |
| <a name="input_enable_tls_inspection"></a> [enable\_tls\_inspection](#input\_enable\_tls\_inspection) | enable nfw tls inspection true/false. deploy\_aws\_nfw must be true to enable this | `bool` | `false` | no |
| <a name="input_enable_vpn_gateway"></a> [enable\_vpn\_gateway](#input\_enable\_vpn\_gateway) | Should be true if you want to create a new VPN Gateway resource and attach it to the VPC | `bool` | `false` | no |
| <a name="input_external_nat_ip_ids"></a> [external\_nat\_ip\_ids](#input\_external\_nat\_ip\_ids) | List of EIP IDs to be assigned to the NAT Gateways (used in combination with reuse\_nat\_ips) | `list(string)` | `[]` | no |
| <a name="input_firewall_custom_routes"></a> [firewall\_custom\_routes](#input\_firewall\_custom\_routes) | Custom routes for Firewall Subnets | `list(map(string))` | `[]` | no |
| <a name="input_firewall_route_table_tags"></a> [firewall\_route\_table\_tags](#input\_firewall\_route\_table\_tags) | Additional tags for the firewall route tables | `map(string)` | `{}` | no |
| <a name="input_firewall_subnet_name_tag"></a> [firewall\_subnet\_name\_tag](#input\_firewall\_subnet\_name\_tag) | Additional name tag for the firewall subnets | `map(string)` | `{}` | no |
| <a name="input_flow_log_destination_arn"></a> [flow\_log\_destination\_arn](#input\_flow\_log\_destination\_arn) | The ARN of the Cloudwatch log destination for Flow Logs | `string` | `null` | no |
| <a name="input_flow_log_destination_type"></a> [flow\_log\_destination\_type](#input\_flow\_log\_destination\_type) | Type of flow log destination. Can be s3 or cloud-watch-logs | `string` | n/a | yes |
| <a name="input_igw_tags"></a> [igw\_tags](#input\_igw\_tags) | Additional tags for the internet gateway | `map(string)` | `{}` | no |
| <a name="input_instance_tenancy"></a> [instance\_tenancy](#input\_instance\_tenancy) | A tenancy option for instances launched into the VPC | `string` | `"default"` | no |
| <a name="input_intra_custom_routes"></a> [intra\_custom\_routes](#input\_intra\_custom\_routes) | Custom routes for Intra Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    transit_gateway_id         = optional(string, null)<br/>    vpc_endpoint_id            = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_intra_route_table_tags"></a> [intra\_route\_table\_tags](#input\_intra\_route\_table\_tags) | Additional tags for the intra route tables | `map(string)` | `{}` | no |
| <a name="input_intra_subnet_tags"></a> [intra\_subnet\_tags](#input\_intra\_subnet\_tags) | Additional tags for the intra subnets | `map(string)` | `{}` | no |
| <a name="input_karpenter_discovery_tag_value"></a> [karpenter\_discovery\_tag\_value](#input\_karpenter\_discovery\_tag\_value) | Custom value for the karpenter.sh/discovery tag. Defaults to eks\_cluster\_name if empty. | `string` | `""` | no |
| <a name="input_manage_default_vpc"></a> [manage\_default\_vpc](#input\_manage\_default\_vpc) | Should be true to adopt and manage Default VPC | `bool` | `false` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | Should be false if you do not want to auto-assign public IP on launch | `bool` | `true` | no |
| <a name="input_nat_eip_tags"></a> [nat\_eip\_tags](#input\_nat\_eip\_tags) | Additional tags for the NAT EIP | `map(string)` | `{}` | no |
| <a name="input_nat_gateway_tags"></a> [nat\_gateway\_tags](#input\_nat\_gateway\_tags) | Additional tags for the NAT gateways | `map(string)` | `{}` | no |
| <a name="input_nfw_kms_key_arn"></a> [nfw\_kms\_key\_arn](#input\_nfw\_kms\_key\_arn) | ARN of the KMS key to use for NFW encryption | `string` | `null` | no |
| <a name="input_one_nat_gateway_per_az"></a> [one\_nat\_gateway\_per\_az](#input\_one\_nat\_gateway\_per\_az) | Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs`. | `bool` | `false` | no |
| <a name="input_private_custom_routes"></a> [private\_custom\_routes](#input\_private\_custom\_routes) | Custom routes for Private Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    transit_gateway_id         = optional(string, null)<br/>    vpc_peering_connection_id  = optional(string, null)<br/>    vpc_endpoint_id            = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_private_route_table_tags"></a> [private\_route\_table\_tags](#input\_private\_route\_table\_tags) | Additional tags for the private route tables | `map(string)` | `{}` | no |
| <a name="input_propagate_private_route_tables_vgw"></a> [propagate\_private\_route\_tables\_vgw](#input\_propagate\_private\_route\_tables\_vgw) | Should be true if you want route table propagation | `bool` | `false` | no |
| <a name="input_propagate_public_route_tables_vgw"></a> [propagate\_public\_route\_tables\_vgw](#input\_propagate\_public\_route\_tables\_vgw) | Should be true if you want route table propagation | `bool` | `false` | no |
| <a name="input_public_custom_routes"></a> [public\_custom\_routes](#input\_public\_custom\_routes) | Custom routes for Public Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    internet_route             = optional(bool, null)<br/>    transit_gateway_id         = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_public_route_table_tags"></a> [public\_route\_table\_tags](#input\_public\_route\_table\_tags) | Additional tags for the public route tables | `map(string)` | `{}` | no |
| <a name="input_redshift_custom_routes"></a> [redshift\_custom\_routes](#input\_redshift\_custom\_routes) | Custom routes for Redshift Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    transit_gateway_id         = optional(string, null)<br/>    vpc_endpoint_id            = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_redshift_route_table_tags"></a> [redshift\_route\_table\_tags](#input\_redshift\_route\_table\_tags) | Additional tags for the redshift route tables | `map(string)` | `{}` | no |
| <a name="input_redshift_subnet_group_name"></a> [redshift\_subnet\_group\_name](#input\_redshift\_subnet\_group\_name) | Optional custom resource name for the Redshift subnet group | `string` | `null` | no |
| <a name="input_redshift_subnet_group_tags"></a> [redshift\_subnet\_group\_tags](#input\_redshift\_subnet\_group\_tags) | Additional tags for the redshift subnet group | `map(string)` | `{}` | no |
| <a name="input_redshift_subnet_tags"></a> [redshift\_subnet\_tags](#input\_redshift\_subnet\_tags) | Additional tags for the redshift subnets | `map(string)` | `{}` | no |
| <a name="input_resource_prefix"></a> [resource\_prefix](#input\_resource\_prefix) | Prefix to be added to resource names as identifier | `string` | `""` | no |
| <a name="input_reuse_nat_ips"></a> [reuse\_nat\_ips](#input\_reuse\_nat\_ips) | Should be true if you don't want EIPs to be created for your NAT Gateways and will instead pass them in via the 'external\_nat\_ip\_ids' variable | `bool` | `false` | no |
| <a name="input_s3_access_logs_bucket"></a> [s3\_access\_logs\_bucket](#input\_s3\_access\_logs\_bucket) | bucket id for s3 access logs bucket | `string` | `""` | no |
| <a name="input_s3_kms_key_arn"></a> [s3\_kms\_key\_arn](#input\_s3\_kms\_key\_arn) | Customer KMS Key id for Cloudwatch Log encryption | `string` | `""` | no |
| <a name="input_secondary_cidr_blocks"></a> [secondary\_cidr\_blocks](#input\_secondary\_cidr\_blocks) | List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool | `list(string)` | `[]` | no |
| <a name="input_single_nat_gateway"></a> [single\_nat\_gateway](#input\_single\_nat\_gateway) | Should be true if you want to provision a single shared NAT Gateway across all of your private networks | `bool` | `false` | no |
| <a name="input_subnet_az_mapping"></a> [subnet\_az\_mapping](#input\_subnet\_az\_mapping) | Optional explicit mapping of subnets to AZs - defaults to distributing across AZs | `map(string)` | `{}` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | n/a | <pre>list(object({<br/>    custom_name       = optional(string)<br/>    tag               = optional(string)<br/>    cidr              = string<br/>    type              = string<br/>    availability_zone = string<br/>    eks               = optional(bool, false)<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to add to all resources | `map(string)` | `{}` | no |
| <a name="input_tgw_custom_routes"></a> [tgw\_custom\_routes](#input\_tgw\_custom\_routes) | Custom routes for TGW Subnets | <pre>list(object({<br/>    destination_cidr_block     = optional(string, null)<br/>    destination_prefix_list_id = optional(string, null)<br/>    network_interface_id       = optional(string, null)<br/>    transit_gateway_id         = optional(string, null)<br/>    vpc_endpoint_id            = optional(string, null)<br/>  }))</pre> | `[]` | no |
| <a name="input_tgw_route_table_tags"></a> [tgw\_route\_table\_tags](#input\_tgw\_route\_table\_tags) | Additional tags for the tgw route tables | `map(string)` | `{}` | no |
| <a name="input_tls_cert_arn"></a> [tls\_cert\_arn](#input\_tls\_cert\_arn) | TLS Certificate ARN | `string` | `""` | no |
| <a name="input_tls_description"></a> [tls\_description](#input\_tls\_description) | Description for the TLS Inspection | `string` | `"TLS Oubound Inspection"` | no |
| <a name="input_tls_destination_cidrs"></a> [tls\_destination\_cidrs](#input\_tls\_destination\_cidrs) | Destination CIDRs for TLS Inspection | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_tls_destination_from_port"></a> [tls\_destination\_from\_port](#input\_tls\_destination\_from\_port) | Destination Port for TLS Inspection | `number` | `443` | no |
| <a name="input_tls_destination_to_port"></a> [tls\_destination\_to\_port](#input\_tls\_destination\_to\_port) | Destination Port for TLS Inspection | `number` | `443` | no |
| <a name="input_tls_source_cidr"></a> [tls\_source\_cidr](#input\_tls\_source\_cidr) | Source CIDR for TLS Inspection | `string` | `"0.0.0.0/0"` | no |
| <a name="input_tls_source_from_port"></a> [tls\_source\_from\_port](#input\_tls\_source\_from\_port) | Source Port for TLS Inspection | `number` | `0` | no |
| <a name="input_tls_source_to_port"></a> [tls\_source\_to\_port](#input\_tls\_source\_to\_port) | Source Port for TLS Inspection | `number` | `65535` | no |
| <a name="input_vpc_endpoint_security_groups"></a> [vpc\_endpoint\_security\_groups](#input\_vpc\_endpoint\_security\_groups) | Map of security groups to create for VPC endpoints | <pre>map(object({<br/>    name        = string<br/>    description = optional(string, "Security group for VPC endpoint")<br/>    ingress_rules = optional(list(object({<br/>      description      = optional(string)<br/>      from_port        = number<br/>      to_port          = number<br/>      protocol         = string<br/>      cidr_blocks      = optional(list(string), [])<br/>      ipv6_cidr_blocks = optional(list(string), [])<br/>      security_groups  = optional(list(string), [])<br/>      self             = optional(bool, false)<br/>    })), [])<br/>    egress_rules = optional(list(object({<br/>      description      = optional(string)<br/>      from_port        = number<br/>      to_port          = number<br/>      protocol         = string<br/>      cidr_blocks      = optional(list(string), [])<br/>      ipv6_cidr_blocks = optional(list(string), [])<br/>      security_groups  = optional(list(string), [])<br/>      self             = optional(bool, false)<br/>    })), [])<br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_endpoints"></a> [vpc\_endpoints](#input\_vpc\_endpoints) | Map of VPC endpoint definitions to create | <pre>map(object({<br/>    service_name        = optional(string)     # If not provided, standard AWS service name will be constructed<br/>    service_type        = string               # "Interface", "Gateway", or "GatewayLoadBalancer"<br/>    private_dns_enabled = optional(bool, true) # Only applicable for Interface endpoints<br/>    auto_accept         = optional(bool, false)<br/>    policy              = optional(string) # JSON policy document<br/>    security_group_ids  = optional(list(string), [])<br/>    tags                = optional(map(string), {})<br/>    subnet_ids          = optional(list(string)) # Override default subnet_ids if needed<br/>    # Required only for GatewayLoadBalancer endpoints<br/>    ip_address_type = optional(string) # "ipv4" or "dualstack"<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | Name to assign to the AWS VPC | `string` | n/a | yes |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | Additional tags for the VPC | `map(string)` | `{}` | no |
| <a name="input_vpn_gateway_custom_name"></a> [vpn\_gateway\_custom\_name](#input\_vpn\_gateway\_custom\_name) | Specifies a custom name to assign to the VPN; if not set, a name will be generated from var.resource\_prefix | `any` | `null` | no |
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
| <a name="output_subnets"></a> [subnets](#output\_subnets) | List of objects containing all subnet IDs and CIDRs by name |
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
## Tree
```
.
|-- CHANGELOG.md
|-- CONTRIBUTING.md
|-- LICENSE
|-- README.md
|-- coalfire_logo.png
|-- example
|   |-- prior-versions
|   |   |-- README.md
|   |   |-- other-examples
|   |   |   |-- example-with-tls-inspection.tf
|   |   |   |-- example-without-network-firewall.tf
|   |   |-- vpc-app-account
|   |       |-- app-networking.auto.tfvars
|   |       |-- locals.tf
|   |       |-- mgmt.tf
|   |       |-- outputs.tf
|   |       |-- providers.tf
|   |       |-- remote-data.tf
|   |       |-- required_providers.tf
|   |       |-- variables.tf
|   |-- vpc-nfw
|       |-- locals.tf
|       |-- mgmt.tf
|       |-- nfw_policies.tf
|       |-- outputs.tf
|       |-- providers.tf
|       |-- remote-data.tf
|       |-- required_providers.tf
|       |-- suricata.json
|       |-- variables.tf
|       |-- vpc_nfw.auto.tfvars
|-- flowlog.tf
|-- locals.tf
|-- main.tf
|-- modules
|   |-- aws-network-firewall
|   |   |-- README.md
|   |   |-- coalfire_logo.png
|   |   |-- locals.tf
|   |   |-- main.tf
|   |   |-- nfw-base-suricata-rules.json
|   |   |-- output.tf
|   |   |-- required_providers.tf
|   |   |-- tls.tf
|   |   |-- variables.tf
|   |-- vpc-endpoint
|       |-- README.md
|       |-- locals.tf
|       |-- main.tf
|       |-- outputs.tf
|       |-- variables.tf
|-- outputs.tf
|-- release-please-config.json
|-- required_providers.tf
|-- routes.tf
|-- subnets.tf
|-- test
|   |-- src
|       |-- vpc_endpoints_with_nfw_test.go
|-- variables.tf
```
