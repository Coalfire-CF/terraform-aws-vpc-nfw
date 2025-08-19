module "mgmt_vpc" {
  source = "git::https://github.com/Coalfire-CF/terraform-aws-vpc-nfw.git?ref=vx.x.x"

  name = "${var.resource_prefix}-mgmt"
  cidr = var.mgmt_vpc_cidr
  azs  = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]

  private_subnets = local.private_subnets # Map of Name -> CIDR, please note this goes alphabetically in order
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

  firewall_subnets       = local.firewall_subnets
  firewall_subnet_suffix = "firewall"

  public_subnets       = local.public_subnets # Map of Name -> CIDR
  public_subnet_suffix = "public"

  single_nat_gateway     = var.single_nat_gateway     # false
  enable_nat_gateway     = var.enable_nat_gateway     # true
  one_nat_gateway_per_az = var.one_nat_gateway_per_az # true
  enable_vpn_gateway     = var.enable_vpn_gateway     # false
  enable_dns_hostnames   = var.enable_dns_hostnames   # true

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
