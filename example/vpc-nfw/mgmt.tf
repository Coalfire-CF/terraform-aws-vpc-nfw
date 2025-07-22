module "mgmt_vpc" {
  # Note: Checkov recommends pointing to hash instead of tags since hashes are immutable unlike tags
  source = "git::https://github.com/Coalfire-CF/terraform-aws-vpc-nfw.git?ref=vx.x.x"

  name = "${var.resource_prefix}-mgmt"
  cidr = var.mgmt_vpc_cidr
  azs  = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]

  private_subnets = local.private_subnets
  private_subnet_tags = { #please note this goes alphabetically in order
    "0" = "config"
    "1" = "config"
    "2" = "database"
    "3" = "database"
    "4" = "iam"
    "5" = "iam"
    "6" = "secops"
    "7" = "secops"
    "8" = "siem"
    "9" = "siem"
  }

  tgw_subnets = [
    "10.1.255.0/28",
    "10.1.255.16/28"
  ]
  tgw_subnet_tags = {
    "0" = "TGW"
    "1" = "TGW"
  }

  public_subnets       = local.public_subnets
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
  deploy_aws_nfw                        = var.deploy_aws_nfw
  delete_protection                     = var.delete_protection
  aws_nfw_prefix                        = var.resource_prefix
  aws_nfw_name                          = "${var.resource_prefix}-nfw"
  aws_nfw_fivetuple_stateful_rule_group = local.fivetuple_rule_group
  aws_nfw_suricata_stateful_rule_group  = local.suricata_rule_group_shrd_svcs
  nfw_kms_key_id                        = data.terraform_remote_state.account-setup.outputs.nfw_kms_key_id

  # When deploying NFW, firewall_subnets must be specified
  firewall_subnets       = local.firewall_subnets
  firewall_subnet_suffix = "firewall"
}