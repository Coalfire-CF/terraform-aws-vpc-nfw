module "prod_vpc" {
  source = "git::https://github.com/Coalfire-CF/terraform-aws-vpc-nfw.git?ref=vx.x.x"

  providers = {
    aws = aws.example-app
  }

  name = "${var.resource_prefix}-${var.environment}"
  cidr = var.app_vpc_cidr
  azs  = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]

  private_subnets = local.private_subnets
  private_subnet_tags = {
    "0" = "db"
    "1" = "db"
    "2" = "compute"
    "3" = "compute"
    "4" = "secops"
    "5" = "secops"
  }

  tgw_subnets = local.tgw_subnets
  tgw_subnet_tags = {
    "0" = "tgw"
    "1" = "tgw"
  }

  firewall_subnets       = local.firewall_subnets
  firewall_subnet_suffix = "firewall"

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
}