module "mgmt_vpc" {
  # Note: Checkov recommends pointing to hash instead of tags since hashes are immutable unlike tags
  source = "git::https://github.com/Coalfire-CF/terraform-aws-vpc-nfw.git?ref=vx.x.x"

  name = "${var.resource_prefix}-mgmt"
  cidr = var.mgmt_vpc_cidr
  azs  = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]

  subnets = [
    # Firewall subnets
    {
      tag               = "firewall"
      cidr              = "10.0.0.0/24"
      type              = "firewall"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "firewall"
      cidr              = "10.0.1.0/24"
      type              = "firewall"
      availability_zone = "us-gov-west-1b"
    },
    # Public subnets
    {
      tag               = "public"
      cidr              = "10.0.2.0/24"
      type              = "public"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "public"
      cidr              = "10.0.3.0/24"
      type              = "public"
      availability_zone = "us-gov-west-1b"
    },
    # Private subnets
    {
      tag               = "iam"
      cidr              = "10.0.4.0/24"
      type              = "private"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "iam"
      cidr              = "10.0.5.0/24"
      type              = "private"
      availability_zone = "us-gov-west-1b"
    },
    {
      tag               = "secops"
      cidr              = "10.0.6.0/24"
      type              = "private"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "secops"
      cidr              = "10.0.7.0/24"
      type              = "private"
      availability_zone = "us-gov-west-1b"
    },
    {
      tag               = "config"
      cidr              = "10.0.8.0/24"
      type              = "private"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "config"
      cidr              = "10.0.9.0/24"
      type              = "private"
      availability_zone = "us-gov-west-1b"
    },
    # Database subnets
    {
      tag               = "database"
      cidr              = "10.0.10.0/24"
      type              = "database"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "database"
      cidr              = "10.0.11.0/24"
      type              = "tgw"
      availability_zone = "us-gov-west-1b"
    },
    # TGW subnets
    {
      tag               = "tgw"
      cidr              = "10.0.12.0/24"
      type              = "tgw"
      availability_zone = "us-gov-west-1a"
    },
    {
      tag               = "tgw"
      cidr              = "10.0.13.0/24"
      type              = "tgw"
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
  cloudwatch_log_group_kms_key_id        = data.terraform_remote_state.account-setup.outputs.cloudwatch_kms_key_arn

  ### Network Firewall ###
  deploy_aws_nfw                        = var.deploy_aws_nfw
  delete_protection                     = var.delete_protection
  aws_nfw_prefix                        = var.resource_prefix
  aws_nfw_name                          = "${var.resource_prefix}-nfw"
  aws_nfw_fivetuple_stateful_rule_group = local.fivetuple_rule_group
  aws_nfw_suricata_stateful_rule_group  = local.suricata_rule_group_shrd_svcs
  nfw_kms_key_id                        = data.terraform_remote_state.account-setup.outputs.nfw_kms_key_id
}
