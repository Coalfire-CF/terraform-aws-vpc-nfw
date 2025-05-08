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
  public_subnet_suffix = "dmz"


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
  aws_nfw_suricata_stateful_rule_group  = local.suricata_rule_group_shrd_svcs
  nfw_kms_key_id                        = aws_kms_key.nfw_key.arn

  # When deploying NFW, firewall_subnets must be specified
  firewall_subnets       = local.firewall_subnets
  firewall_subnet_suffix = "firewall"

 ### TLS Inspection ###
  enable_tls_inspection = var.enable_tls_inspection
  tls_cert_arn          = var.tls_cert_arn
  tls_description       = "TLS Inspection"
  tls_destination_cidrs = var.tls_destination_cidrs

  /* Add Additional tags here */
  tags = {
    Owner       = var.resource_prefix
    Environment = "mgmt"
    createdBy   = "terraform"
  }
}
