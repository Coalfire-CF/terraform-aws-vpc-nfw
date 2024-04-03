locals {
  max_subnet_length = max(length(var.private_subnets), length(var.elasticache_subnets), length(var.database_subnets), length(var.redshift_subnets), length(var.firewall_subnets), length(var.tgw_subnets))
  nat_gateway_count = var.single_nat_gateway ? 1 : (var.one_nat_gateway_per_az ? length(var.azs) : local.max_subnet_length)

  nfw_subnets = [for s in aws_subnet.firewall : s.id]

  # Use `local.vpc_id` to give a hint to Terraform that subnets should be deleted before secondary CIDR blocks can be free!
  vpc_id = element(
  concat(aws_vpc_ipv4_cidr_block_association.this[*].vpc_id, aws_vpc.this[*].id, tolist([""])), 0)
}

######
# VPC
######
resource "aws_vpc" "this" {
  #checkov:skip=CKV2_AWS_11: "Ensure VPC flow logging is enabled in all VPCs" - False positive
  cidr_block                       = var.cidr
  instance_tenancy                 = var.instance_tenancy
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support
  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block

  tags = merge(tomap({
    "Name" = format("%s", var.name)
  }), var.tags, var.vpc_tags)
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  count = length(var.secondary_cidr_blocks) > 0 ? length(var.secondary_cidr_blocks) : 0

  vpc_id = aws_vpc.this.id

  cidr_block = element(var.secondary_cidr_blocks, count.index)
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
}

###################
# DHCP Options Set
###################
resource "aws_vpc_dhcp_options" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  domain_name          = var.dhcp_options_domain_name
  domain_name_servers  = var.dhcp_options_domain_name_servers
  ntp_servers          = var.dhcp_options_ntp_servers
  netbios_name_servers = var.dhcp_options_netbios_name_servers
  netbios_node_type    = var.dhcp_options_netbios_node_type

  tags = merge(tomap({
    "Name" = format("%s-dhcp-options", var.name)
  }), var.tags, var.dhcp_options_tags)
}

###############################
# DHCP Options Set Association
###############################
resource "aws_vpc_dhcp_options_association" "this" {
  count = var.enable_dhcp_options ? 1 : 0

  vpc_id          = local.vpc_id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "this" {
  count = length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(tomap({
    "Name" = format("%s", var.name)
  }), var.tags, var.igw_tags)
}

###################
# Network Firewall
###################
module "aws_network_firewall" {
  source = "./modules/aws-network-firewall"

  count = var.deploy_aws_nfw ? 1 : 0

  firewall_name                          = var.aws_nfw_name
  prefix                                 = var.aws_nfw_prefix
  stateless_rule_group                   = var.aws_nfw_stateless_rule_group
  fivetuple_stateful_rule_group          = var.aws_nfw_fivetuple_stateful_rule_group
  suricata_stateful_rule_group           = var.aws_nfw_suricata_stateful_rule_group
  domain_stateful_rule_group             = var.aws_nfw_domain_stateful_rule_group
  subnet_mapping                         = local.nfw_subnets
  vpc_id                                 = local.vpc_id
  nfw_kms_key_id                         = var.nfw_kms_key_id
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = var.cloudwatch_log_group_kms_key_id
  delete_protection                      = var.delete_protection
}

##############
# NAT Gateway
##############
# Workaround for interpolation not being able to "short-circuit" the evaluation of the conditional branch that doesn't end up being used
# Source: https://github.com/hashicorp/terraform/issues/11566#issuecomment-289417805
#
# The logical expression would be
#
#    nat_gateway_ips = var.reuse_nat_ips ? var.external_nat_ip_ids : aws_eip.nat[*].id
#
# but then when count of aws_eip.nat[*].id is zero, this would throw a resource not found error on aws_eip.nat[*].id.
locals {
  nat_gateway_ips = split(",", (var.reuse_nat_ips ? join(",", var.external_nat_ip_ids) : join(",", aws_eip.nat[*].id)))
}

resource "aws_eip" "nat" {
  #checkov:skip=CKV2_AWS_19: "Ensure that all EIP addresses allocated to a VPC are attached to EC2 instances" - N/A as it is for NAT gateway
  count = (var.enable_nat_gateway && !var.reuse_nat_ips) ? local.nat_gateway_count : 0

  domain = "vpc"

  tags = merge(tomap({
    "Name" = format("%s-%s", var.name, element(var.azs, (var.single_nat_gateway ? 0 : count.index)))
  }), var.tags, var.nat_eip_tags)
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = element(local.nat_gateway_ips, (var.single_nat_gateway ? 0 : count.index))
  subnet_id     = element(aws_subnet.public.*.id, (var.single_nat_gateway ? 0 : count.index))

  tags = merge(tomap({
    "Name" = format("%s-%s", var.name, element(var.azs, (var.single_nat_gateway ? 0 : count.index)))
  }), var.tags, var.nat_gateway_tags)

  depends_on = [aws_internet_gateway.this, aws_subnet.public]
}

##############
# VPN Gateway
##############
resource "aws_vpn_gateway" "this" {
  count = var.enable_vpn_gateway ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(tomap({
    "Name" = format("%s", var.name)
  }), var.tags, var.vpn_gateway_tags)
}

resource "aws_vpn_gateway_attachment" "this" {
  count = var.vpn_gateway_id != "" ? 1 : 0

  vpc_id         = local.vpc_id
  vpn_gateway_id = var.vpn_gateway_id
}

resource "aws_vpn_gateway_route_propagation" "public" {
  count = var.propagate_public_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? 1 : 0

  route_table_id = element(aws_route_table.public[*].id, count.index)
  vpn_gateway_id = element(concat(aws_vpn_gateway.this[*].id, aws_vpn_gateway_attachment.this[*].vpn_gateway_id), count.index)
}

resource "aws_vpn_gateway_route_propagation" "private" {
  count = var.propagate_private_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? length(var.private_subnets) : 0

  route_table_id = element(aws_route_table.private[*].id, count.index)
  vpn_gateway_id = element(concat(aws_vpn_gateway.this[*].id, aws_vpn_gateway_attachment.this[*].vpn_gateway_id), count.index)
}

###########
# Defaults
###########
resource "aws_default_vpc" "this" {
  count = var.manage_default_vpc ? 1 : 0

  enable_dns_support   = var.default_vpc_enable_dns_support
  enable_dns_hostnames = var.default_vpc_enable_dns_hostnames

  tags = merge(tomap({
    "Name" = format("%s", var.default_vpc_name)
  }), var.tags, var.default_vpc_tags)
}
