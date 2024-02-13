module "mgmt_vpc" {
  # Note: Checkov recommends pointing to hash instead of tags since hashes are immutable unlike tags
  source = "../../."
  providers = {
    aws = aws.mgmt
  }

  name = "${var.resource_prefix}-mgmt"

  delete_protection = var.delete_protection

  cidr = var.mgmt_vpc_cidr

  azs = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]

  ##if using AWS workspaces https://docs.aws.amazon.com/workspaces/latest/adminguide/azs-workspaces.html
  ## us-east-1 = use1-az2, use1-az4, use1-az6
  ## us-west-2 = usw2-az1, usw2-az2, usw2-az3
  ## us-gov-west-1 = usgw1-az1, usgw1-az2, usgw1-az3
  ## us-gov-east-1 = usge1-az1, usge1-az2, usge1-az3
  workspaces_azs = ["usgw1-az1", "usgw1-az2", "usgw1-az3"]
  workspaces_subnets = local.workspaces_subnets
  workspaces_subnet_tags = {
    "0" = "workspaces"
    "1" = "workspaces"
    "2" = "workspaces"
  }

  private_subnets = local.private_subnets
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

  public_subnets       = local.public_subnets
  public_subnet_suffix = "public"


  single_nat_gateway     = false
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true

  flow_log_destination_type              = "cloud-watch-logs"
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_kms_key_id        = aws_kms_key.cloudwatch_key.arn

  ### Network Firewall ###
  deploy_aws_nfw                        = true
  aws_nfw_prefix                        = var.resource_prefix
  aws_nfw_name                          = "mvp-test-nfw"
  aws_nfw_fivetuple_stateful_rule_group = local.fivetuple_rule_group_shrd_svcs
  aws_nfw_domain_stateful_rule_group    = local.domain_stateful_rule_group_shrd_svcs
  aws_nfw_suricata_stateful_rule_group  = local.suricata_rule_group_shrd_svcs
  nfw_kms_key_id                        = aws_kms_key.nfw_key.arn

  # When deploying NFW, firewall_subnets must be specified
  firewall_subnets       = local.firewall_subnets
  firewall_subnet_suffix = "firewall"

  /* Add Additional tags here */
  tags = {
    Owner       = var.resource_prefix
    Environment = "mgmt"
    createdBy   = "terraform"
  }
}