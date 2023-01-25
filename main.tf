locals {
  max_subnet_length = max(length(var.private_subnets), length(var.elasticache_subnets), length(var.database_subnets), length(var.redshift_subnets))
  nat_gateway_count = var.single_nat_gateway ? 1 : (var.one_nat_gateway_per_az ? length(var.azs) : local.max_subnet_length)

  nfw_subnets = [for s in aws_subnet.firewall : s.id]

  # Use `local.vpc_id` to give a hint to Terraform that subnets should be deleted before secondary CIDR blocks can be free!
  vpc_id = element(
    concat(aws_vpc_ipv4_cidr_block_association.this.*.vpc_id, aws_vpc.this.*.id, tolist([
      ""
    ])), 0)


}

######
# VPC
######
resource "aws_vpc" "this" {
  #count = var.create_vpc ? 1 : 0

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
# VPC Flow Log
###############################
resource "aws_flow_log" "this" {
  count           = var.enable_vpcflowlog ? 1 : 0
  iam_role_arn    = aws_iam_role.flowlogs_role.arn
  log_destination = aws_cloudwatch_log_group.this[
  0
  ].arn
  traffic_type = "ALL"
  vpc_id       = local.vpc_id
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.enable_vpcflowlog ? 1 : 0
  name  = format("vpcflowlogs-%s", local.vpc_id)
  tags  = merge(tomap({
    "Name" = format("%s", var.name)
  }), var.tags, var.vpcflowlog_tags)

}
resource "aws_flow_log" "thisS3" {
  count                    = var.enable_vpcflowlog_toS3 ? 1 : 0
  log_destination          = var.vpcflowlog_s3_arn
  log_destination_type     = "s3"
  traffic_type             = "ALL"
  max_aggregation_interval = 600
  vpc_id                   = local.vpc_id
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
# Network Firewall Functions
###################
module "aws_network_firewall" {
  source = "./modules/aws-network-firewall"

  count = var.deploy_aws_nfw ? 1 : 0

  firewall_name                 = var.aws_nfw_name
  prefix                        = var.aws_nfw_prefix
  stateless_rule_group          = var.aws_nfw_stateless_rule_group
  fivetuple_stateful_rule_group = var.aws_nfw_fivetuple_stateful_rule_group
  suricata_stateful_rule_group  = var.aws_nfw_suricata_stateful_rule_group
  domain_stateful_rule_group    = var.aws_nfw_domain_stateful_rule_group
  subnet_mapping                = local.nfw_subnets
  vpc_id                        = local.vpc_id
}


################
# Publiс routes
################
resource "aws_route_table" "public" {
  count = length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  vpc_id = local.vpc_id

  tags = merge(tomap({
    "Name" = (format("%s-public-%s-rtb", var.name, element(var.azs, count.index)))
  }), var.tags, var.public_route_table_tags)
}

resource "aws_route" "public_internet_gateway" {
  count = var.deploy_aws_nfw ? 0 : length(var.public_subnets)

  route_table_id = aws_route_table.public[
  0
  ].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[
  0
  ].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "nfw_public_internet_gateway" {
  count = var.deploy_aws_nfw ? length(var.firewall_subnets) : 0

  route_table_id         = aws_route_table.firewall[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "aws_nfw_public_internet" {
  count = var.deploy_aws_nfw ? length(var.public_subnets) : 0

  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = module.aws_network_firewall[0].endpoint_id[count.index]

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table" "aws_nfw_igw_rtb" {
  count = var.deploy_aws_nfw ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(tomap({
    "Name" = (format("%s-igw-rtb", var.name))
  }), var.tags, var.public_route_table_tags)
}

resource "aws_route" "aws_nfw_igw_rt" {
  count = var.deploy_aws_nfw ? length(var.firewall_subnets) : 0

  route_table_id         = aws_route_table.aws_nfw_igw_rtb[0].id
  destination_cidr_block = var.public_subnets[count.index]
  vpc_endpoint_id        = module.aws_network_firewall[0].endpoint_id[count.index]

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "nfw_igw" {
  count = var.deploy_aws_nfw ? 1 : 0

  gateway_id     = aws_internet_gateway.this[0].id
  route_table_id = aws_route_table.aws_nfw_igw_rtb[0].id
}


#################
# Private routes
# There are so many routing tables as the largest amount of subnets of each type (really?)
#################
resource "aws_route_table" "private" {
  count = local.max_subnet_length > 0 ? local.nat_gateway_count : 0

  vpc_id = local.vpc_id

  tags = merge(tomap({
    "Name" = (var.single_nat_gateway ? "${var.name}-${var.private_subnet_suffix}" : format("%s-${var.private_subnet_suffix}-%s-rtb", var.name, element(var.azs, count.index)))
  }), var.tags, var.private_route_table_tags)

  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    ignore_changes = [propagating_vgws]
  }
}

#################
# Firewall routes
# There are so many routing tables as the largest amount of subnets of each type (really?)
#################
resource "aws_route_table" "firewall" {
  count = length(var.firewall_subnets) > 0 ? length(var.firewall_subnets) : 0

  vpc_id = local.vpc_id

  tags = merge(tomap({
    "Name" = (var.single_nat_gateway ? "${var.name}-${var.firewall_subnet_suffix}" : format("%s-${var.firewall_subnet_suffix}-%s-rtb", var.name, element(var.azs, count.index)))
  }), var.tags, var.firewall_route_table_tags)

  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the private subnets)
    ignore_changes = [propagating_vgws]
  }
}

##############
# SIEM routes
##############

resource "aws_route_table" "siem" {
  count = var.create_siem_subnet_route_table && length(var.siem_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(var.tags, var.siem_route_table_tags, tomap({
    "Name" = "${var.name}-${var.siem_subnet_suffix}-rtb"
  }))
}


#################
# Database routes
#################
resource "aws_route_table" "database" {
  count = var.create_database_subnet_route_table && length(var.database_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(var.tags, var.database_route_table_tags, tomap({
    "Name" = "${var.name}-${var.database_subnet_suffix}-rtb"
  }))
}

#################
# Redshift routes
#################
resource "aws_route_table" "redshift" {
  count = var.create_redshift_subnet_route_table && length(var.redshift_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(var.tags, var.redshift_route_table_tags, tomap({
    "Name" = "${var.name}-${var.redshift_subnet_suffix}-rtb"
  }))
}

#################
# Elasticache routes
#################
resource "aws_route_table" "elasticache" {
  count = var.create_elasticache_subnet_route_table && length(var.elasticache_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(var.tags, var.elasticache_route_table_tags, tomap({
    "Name" = "${var.name}-${var.elasticache_subnet_suffix}-rtb"
  }))
}

#################
# SIEM routes
#################

#################
# Intra routes
#################
resource "aws_route_table" "intra" {
  count = length(var.intra_subnets) > 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(tomap({
    "Name" = "${var.name}-intra-rtb"
  }), var.tags, var.intra_route_table_tags)
}

################
# Firewall subnet
################
resource "aws_subnet" "firewall" {
  count = length(var.firewall_subnets) > 0 ? length(var.firewall_subnets) : 0

  vpc_id     = local.vpc_id
  cidr_block = var.firewall_subnets[
  count.index
  ]
  availability_zone = length(var.firewall_az) > 0 ? lookup(var.firewall_az, count.index) : element(var.azs, count.index)

  tags = merge(tomap({
    "Name" = format("%s-${lower(var.firewall_subnet_suffix)}-%s", var.name, element(var.azs, count.index))
  }), var.tags, var.firewall_subnet_name_tag)
}

################
# Public subnet
################
resource "aws_subnet" "public" {
  count = length(var.public_subnets) > 0 && (!var.one_nat_gateway_per_az || length(var.public_subnets) >= length(var.public_az)) ? length(var.public_subnets) : 0

  vpc_id     = local.vpc_id
  cidr_block = var.public_subnets[
  count.index
  ]
  availability_zone       = length(var.public_az) > 0 ? lookup(var.public_az, count.index) : element(var.azs, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(tomap({
    "Name" = format("%s-${lower(var.public_subnet_suffix)}-%s", var.name, element(var.azs, count.index))
  }), var.tags, var.public_subnet_tags)
}

#################
# Private subnet
#################
resource "aws_subnet" "private" {
  count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  vpc_id     = local.vpc_id
  cidr_block = var.private_subnets[
  count.index
  ]
  availability_zone = length(var.private_az) > 0 ? lookup(var.private_az, count.index) : element(var.azs, count.index)

  tags = merge(tomap({
    "Name" = format("%s-${lower(var.private_subnet_name_tag[count.index])}-%s", var.name, element(var.azs, count.index))
  }), var.tags, var.private_subnet_tags)
}

##################
# Database subnet
##################
resource "aws_subnet" "database" {
  count = length(var.database_subnets) > 0 ? length(var.database_subnets) : 0

  vpc_id     = local.vpc_id
  cidr_block = var.database_subnets[
  count.index
  ]
  availability_zone = element(var.azs, count.index)

  tags = merge(tomap({
    "Name" = format("%s-${var.database_subnet_suffix}-%s", var.name, element(var.azs, count.index))
  }), var.tags, var.database_subnet_tags)
}

resource "aws_db_subnet_group" "database" {
  count = length(var.database_subnets) > 0 && var.create_database_subnet_group ? 1 : 0

  name        = "${lower(var.name)}-backend"
  description = "Database subnet group for ${var.name}"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(tomap({
    "Name" = format("%s", var.name)
  }), var.tags, var.database_subnet_group_tags)
}

##################
# Redshift subnet
##################
resource "aws_subnet" "redshift" {
  count = length(var.redshift_subnets) > 0 ? length(var.redshift_subnets) : 0

  vpc_id     = local.vpc_id
  cidr_block = var.redshift_subnets[
  count.index
  ]
  availability_zone = element(var.azs, count.index)

  tags = merge(tomap({
    "Name" = format("%s-${var.redshift_subnet_suffix}-%s", var.name, element(var.azs, count.index))
  }), var.tags, var.redshift_subnet_tags)
}

resource "aws_redshift_subnet_group" "redshift" {
  count = length(var.redshift_subnets) > 0 ? 1 : 0

  name        = var.name
  description = "Redshift subnet group for ${var.name}"
  subnet_ids  = [
    aws_subnet.redshift.*.id
  ]

  tags = merge(tomap({
    "Name" = format("%s", var.name)
  }), var.tags, var.redshift_subnet_group_tags)
}

#####################
# SIEM subnet
#####################
resource "aws_subnet" "siem" {
  count = length(var.siem_subnets) > 0 ? length(var.siem_subnets) : 0

  vpc_id     = local.vpc_id
  cidr_block = var.siem_subnets[
  count.index
  ]
  availability_zone = element(var.azs, count.index)

  tags = merge(tomap({
    "Name" = format("%s-${var.siem_subnet_suffix}-%s", var.name, element(var.azs, count.index))
  }), var.tags, var.siem_subnet_tags)
}

#####################
# ElastiCache subnet
#####################
resource "aws_subnet" "elasticache" {
  count = length(var.elasticache_subnets) > 0 ? length(var.elasticache_subnets) : 0

  vpc_id     = local.vpc_id
  cidr_block = var.elasticache_subnets[
  count.index
  ]
  availability_zone = element(var.azs, count.index)

  tags = merge(tomap({
    "Name" = format("%s-${var.elasticache_subnet_suffix}-%s", var.name, element(var.azs, count.index))
  }), var.tags, var.elasticache_subnet_tags)
}

resource "aws_elasticache_subnet_group" "elasticache" {
  count = length(var.elasticache_subnets) > 0 ? 1 : 0

  name        = var.name
  description = "ElastiCache subnet group for ${var.name}"
  subnet_ids  = aws_subnet.elasticache[*].id
}

#####################################################
# intra subnets - private subnet without NAT gateway
#####################################################
resource "aws_subnet" "intra" {
  count = length(var.intra_subnets) > 0 ? length(var.intra_subnets) : 0

  vpc_id     = local.vpc_id
  cidr_block = var.intra_subnets[
  count.index
  ]
  availability_zone = element(var.azs, count.index)

  # tags = merge(tomap("Name", format("%s-intra-%s", var.name, element(var.azs, count.index))), var.tags, var.intra_subnet_tags)
  tags = merge(tomap({
    "Name" = format("%s-${var.intra_subnet_name_tag[count.index]}-%s", var.name, element(var.azs, count.index))
  }), var.tags, var.intra_subnet_tags)
}

##############
# NAT Gateway
##############
# Workaround for interpolation not being able to "short-circuit" the evaluation of the conditional branch that doesn't end up being used
# Source: https://github.com/hashicorp/terraform/issues/11566#issuecomment-289417805
#
# The logical expression would be
#
#    nat_gateway_ips = var.reuse_nat_ips ? var.external_nat_ip_ids : aws_eip.nat.*.id
#
# but then when count of aws_eip.nat.*.id is zero, this would throw a resource not found error on aws_eip.nat.*.id.
locals {
  nat_gateway_ips = split(",", (var.reuse_nat_ips ? join(",", var.external_nat_ip_ids) : join(",", aws_eip.nat.*.id)))
}

resource "aws_eip" "nat" {
  count = (var.enable_nat_gateway && !var.reuse_nat_ips) ? local.nat_gateway_count : 0

  vpc = true

  tags = merge(tomap({
    "Name" = format("%s-%s", var.name, element(var.azs, (var.single_nat_gateway ? 0 : count.index)))
  }), var.tags, var.nat_eip_tags)
}

resource "aws_nat_gateway" "this" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = element(local.nat_gateway_ips, (var.single_nat_gateway ? 0 : count.index))
  subnet_id     = element(aws_subnet.public[
  *
  ].id, (var.single_nat_gateway ? 0 : count.index))

  tags = merge(tomap({
    "Name" = format("%s-%s", var.name, element(var.azs, (var.single_nat_gateway ? 0 : count.index)))
  }), var.tags, var.nat_gateway_tags)

  depends_on = [aws_internet_gateway.this, aws_subnet.public]
}

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "siem_nat_gateway" {
  count = var.enable_nat_gateway ? min(length(var.siem_subnets), local.nat_gateway_count) : 0

  route_table_id         = element(aws_route_table.siem.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)

  timeouts {
    create = "5m"
  }
}

######################
# VPC Endpoint for S3
######################
data "aws_vpc_endpoint_service" "s3" {
  count        = var.enable_s3_endpoint ? 1 : 0
  service_type = var.s3_endpoint_type
  service      = "s3"
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id       = local.vpc_id
  service_name = data.aws_vpc_endpoint_service.s3[0].service_name
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count = var.enable_s3_endpoint ? local.nat_gateway_count : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = element(aws_route_table.private.*.id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "intra_s3" {
  count = var.enable_s3_endpoint && length(var.intra_subnets) > 0 ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = element(aws_route_table.intra.*.id, 0)
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  count = var.enable_s3_endpoint && length(var.public_subnets) > 0 ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.public[0].id
}

############################
# VPC Endpoint for DynamoDB
############################
data "aws_vpc_endpoint_service" "dynamodb" {
  count        = var.enable_dynamodb_endpoint ? 1 : 0
  service_type = var.dynamodb_endpoint_type
  service      = "dynamodb"
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id            = local.vpc_id
  vpc_endpoint_type = var.dynamodb_endpoint_type
  service_name      = data.aws_vpc_endpoint_service.dynamodb[0].service_name
}

resource "aws_vpc_endpoint_route_table_association" "private_dynamodb" {
  count = var.enable_dynamodb_endpoint ? local.nat_gateway_count : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = element(aws_route_table.private.*.id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "intra_dynamodb" {
  count = var.enable_dynamodb_endpoint && length(var.intra_subnets) > 0 ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = element(aws_route_table.intra.*.id, 0)
}

resource "aws_vpc_endpoint_route_table_association" "public_dynamodb" {
  count = var.enable_dynamodb_endpoint && length(var.public_subnets) > 0 ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.public[0].id
}

##########################
# Route table association
##########################
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, (var.single_nat_gateway ? 0 : count.index))
}

resource "aws_route_table_association" "firewall" {
  count = var.deploy_aws_nfw ? length(var.firewall_subnets) : 0

  subnet_id      = element(aws_subnet.firewall.*.id, count.index)
  route_table_id = element(aws_route_table.firewall.*.id, (var.single_nat_gateway ? 0 : count.index))
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnets) > 0 ? length(var.database_subnets) : 0

  subnet_id      = element(aws_subnet.database.*.id, count.index)
  route_table_id = element(coalescelist(aws_route_table.database.*.id, aws_route_table.private.*.id), (var.single_nat_gateway || var.create_database_subnet_route_table ? 0 : count.index))
}

resource "aws_route_table_association" "redshift" {
  count = length(var.redshift_subnets) > 0 ? length(var.redshift_subnets) : 0

  subnet_id      = element(aws_subnet.redshift.*.id, count.index)
  route_table_id = element(coalescelist(aws_route_table.redshift.*.id, aws_route_table.private.*.id), (var.single_nat_gateway || var.create_redshift_subnet_route_table ? 0 : count.index))
}

resource "aws_route_table_association" "elasticache" {
  count = length(var.elasticache_subnets) > 0 ? length(var.elasticache_subnets) : 0

  subnet_id      = element(aws_subnet.elasticache.*.id, count.index)
  route_table_id = element(coalescelist(aws_route_table.elasticache.*.id, aws_route_table.private.*.id), (var.single_nat_gateway || var.create_elasticache_subnet_route_table ? 0 : count.index))
}

resource "aws_route_table_association" "intra" {
  count = length(var.intra_subnets) > 0 ? length(var.intra_subnets) : 0

  subnet_id      = element(aws_subnet.intra.*.id, count.index)
  route_table_id = element(aws_route_table.intra.*.id, 0)
}

resource "aws_route_table_association" "public" {
  count = var.deploy_aws_nfw ? 0 : length(var.public_subnets)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id

  depends_on = [
    aws_subnet.public
  ]
}

resource "aws_route_table_association" "nfw_public" {
  count = var.deploy_aws_nfw ? length(var.public_subnets) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[count.index].id

  depends_on = [
    aws_subnet.public
  ]
}

resource "aws_route_table_association" "siem" {
  count = length(var.siem_subnets) > 0 ? length(var.siem_subnets) : 0

  subnet_id      = element(aws_subnet.siem.*.id, count.index)
  route_table_id = aws_route_table.siem[0].id
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

  route_table_id = element(aws_route_table.public.*.id, count.index)
  vpn_gateway_id = element(concat(aws_vpn_gateway.this.*.id, aws_vpn_gateway_attachment.this.*.vpn_gateway_id), count.index)
}

resource "aws_vpn_gateway_route_propagation" "private" {
  count = var.propagate_private_route_tables_vgw && (var.enable_vpn_gateway || var.vpn_gateway_id != "") ? length(var.private_subnets) : 0

  route_table_id = element(aws_route_table.private.*.id, count.index)
  vpn_gateway_id = element(concat(aws_vpn_gateway.this.*.id, aws_vpn_gateway_attachment.this.*.vpn_gateway_id), count.index)
}

###########
# Defaults
###########
resource "aws_default_vpc" "this" {
  count = var.manage_default_vpc ? 1 : 0

  enable_dns_support   = var.default_vpc_enable_dns_support
  enable_dns_hostnames = var.default_vpc_enable_dns_hostnames
  enable_classiclink   = var.default_vpc_enable_classiclink

  tags = merge(tomap({
    "Name" = format("%s", var.default_vpc_name)
  }), var.tags, var.default_vpc_tags)
}
