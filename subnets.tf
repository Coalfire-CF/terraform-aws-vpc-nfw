####################
# Firewall subnets #
####################

resource "aws_subnet" "firewall" {
  count             = length(local.firewall_subnets) > 0 ? length(local.firewall_subnets) : 0
  vpc_id            = local.vpc_id
  cidr_block        = local.firewall_subnets[count.index].cidr
  availability_zone = local.firewall_subnets[count.index].availability_zone
  tags = (
    # if a custom subnet name is defined, set resource tag 'Name' to the custom name, else, generate a name based on Coalfire's naming convention
    local.firewall_subnets[count.index].custom_name != null ?
    merge(tomap({ "Name" = "${local.firewall_subnets[count.index].custom_name}" }), var.tags) :
    merge(tomap({ "Name" = format("%s-${lower(local.firewall_subnets[count.index].type)}-%s", var.resource_prefix, local.firewall_subnets[count.index].availability_zone) }), var.tags)
  )
}

##################
# Public subnets #
##################

resource "aws_subnet" "public" {
  #checkov:skip=CKV_AWS_130: "Ensure VPC subnets do not assign public IP by default" - This is a public subet.
  count                   = length(local.public_subnets) > 0 ? length(local.public_subnets) : 0
  vpc_id                  = local.vpc_id
  cidr_block              = local.public_subnets[count.index].cidr
  availability_zone       = local.public_subnets[count.index].availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags = (
    # if a custom subnet name is defined, set resource tag 'Name' to the custom name, else, generate a name based on Coalfire's naming convention
    local.public_subnets[count.index].custom_name != null ?
    merge(tomap({ "Name" = "${local.public_subnets[count.index].custom_name}" }), var.tags, var.public_eks_tags) :
    merge(tomap({ "Name" = format("%s-${lower(local.public_subnets[count.index].tag)}-%s", var.resource_prefix, local.public_subnets[count.index].availability_zone) }), var.tags, var.public_eks_tags)
  )
}

##################
# Private subnet #
##################

resource "aws_subnet" "private" {
  count             = length(local.private_subnets) > 0 ? length(local.private_subnets) : 0
  vpc_id            = local.vpc_id
  cidr_block        = local.private_subnets[count.index].cidr
  availability_zone = local.private_subnets[count.index].availability_zone
  tags = (
    # if a custom subnet name is defined, set resource tag 'Name' to the custom name, else, generate a name based on Coalfire's naming convention
    local.private_subnets[count.index].custom_name != null ?
    merge(tomap({ "Name" = "${local.private_subnets[count.index].custom_name}" }), var.tags, var.private_eks_tags) :
    merge(tomap({ "Name" = format("%s-${lower(local.private_subnets[count.index].tag)}-%s", var.resource_prefix, local.private_subnets[count.index].availability_zone) }), var.tags, var.private_eks_tags)
  )
}

##############
# TGW subnet #
##############
resource "aws_subnet" "tgw" {
  count             = length(local.tgw_subnets) > 0 ? length(local.tgw_subnets) : 0
  vpc_id            = local.vpc_id
  cidr_block        = local.tgw_subnets[count.index].cidr
  availability_zone = local.tgw_subnets[count.index].availability_zone
  tags = (
    # if a custom subnet name is defined, set resource tag 'Name' to the custom name, else, generate a name based on Coalfire's naming convention
    local.tgw_subnets[count.index].custom_name != null ?
    merge(tomap({ "Name" = "${local.tgw_subnets[count.index].custom_name}" }), var.tags) :
    merge(tomap({ "Name" = format("%s-${lower(local.tgw_subnets[count.index].tag)}-%s", var.resource_prefix, local.tgw_subnets[count.index].availability_zone) }), var.tags)
  )
}

####################################
# Database subnet and subnet group #
####################################

resource "aws_subnet" "database" {
  count             = length(local.database_subnets) > 0 ? length(local.database_subnets) : 0
  vpc_id            = local.vpc_id
  cidr_block        = local.database_subnets[count.index].cidr
  availability_zone = local.database_subnets[count.index].availability_zone
  tags = (
    # if a custom subnet name is defined, set resource tag 'Name' to the custom name, else, generate a name based on Coalfire's naming convention
    local.database_subnets[count.index].custom_name != null ?
    merge(tomap({ "Name" = "${local.database_subnets[count.index].custom_name}" }), var.database_subnet_tags, var.tags) :
    merge(tomap({ "Name" = format("%s-${local.database_subnets[count.index].tag}-%s", var.resource_prefix, local.database_subnets[count.index].availability_zone) }), var.database_subnet_tags, var.tags)
  )
}

resource "aws_db_subnet_group" "database" {
  count = length(aws_subnet.database) > 0 && var.create_database_subnet_group ? 1 : 0
  # if a custom subnet group name is defined, set it, else, generate one based on Coalfire's naming convention
  name        = var.database_subnet_group_name != null ? var.database_subnet_group_name : "${lower(var.resource_prefix)}-backend"
  description = "Database subnet group for ${var.resource_prefix}"
  subnet_ids  = aws_subnet.database[*].id
  tags = (
    # if a custom subnet group name is defined, set resource tag 'Name' to the custom name, else, generate one based on Coalfire's naming convention
    local.tgw_subnets[count.index].custom_name != null ?
    merge(tomap({ "Name" = "${var.database_subnet_group_name}" }), var.database_subnet_tags, var.tags) :
    merge(tomap({ "Name" = format("%s", var.resource_prefix) }), var.tags, var.database_subnet_group_tags)
  )
}

####################################
# Redshift subnet and subnet group #
####################################

resource "aws_subnet" "redshift" {
  count             = length(local.redshift_subnets) > 0 ? length(local.redshift_subnets) : 0
  vpc_id            = local.vpc_id
  cidr_block        = local.redshift_subnets[count.index].cidr
  availability_zone = local.redshift_subnets[count.index].availability_zone
  tags = (
    # if a custom subnet name is defined, set resource tag 'Name' to the custom name, else, generate a name based on Coalfire's naming convention
    local.redshift_subnets[count.index].custom_name != null ?
    merge(tomap({ "Name" = "${local.redshift_subnets[count.index].custom_name}" }), var.tags) :
    merge(tomap({ "Name" = format("%s-${local.redshift_subnets[count.index].tag}-%s", var.resource_prefix, local.redshift_subnets[count.index].availability_zone) }), var.tags)
  )
}

resource "aws_redshift_subnet_group" "redshift" {
  count = length(aws_subnet.redshift) > 0 ? 1 : 0
  # if a custom subnet group name is defined, set it, else, generate one based on Coalfire's naming convention
  name        = var.redshift_subnet_group_name != null ? var.redshift_subnet_group_name : var.resource_prefix
  description = "Redshift subnet group for ${var.resource_prefix}"
  subnet_ids  = aws_subnet.redshift[*].id
  tags = (
    # if a custom subnet group name is defined, set resource tag 'Name' to the custom name, else, generate one based on Coalfire's naming convention
    var.redshift_subnet_group_name != null ?
    merge(tomap({ "Name" = "${var.redshift_subnet_group_name}" }), var.redshift_subnet_group_tags, var.tags) :
    merge(tomap({ "Name" = format("%s", var.resource_prefix) }), var.redshift_subnet_group_tags, var.tags)
  )
}

######################
# ElastiCache subnet #
######################

resource "aws_subnet" "elasticache" {
  count             = length(local.elasticache_subnets) > 0 ? length(local.elasticache_subnets) : 0
  vpc_id            = local.vpc_id
  cidr_block        = local.elasticache_subnets[count.index].cidr
  availability_zone = local.elasticache_subnets[count.index].availability_zone
  tags = (
    local.elasticache_subnets[count.index].custom_name != null ?
    merge(tomap({ "Name" = "${local.elasticache_subnets[count.index].custom_name}" }), var.tags) :
    merge(tomap({ "Name" = format("%s-${local.elasticache_subnets[count.index].tag}-%s", var.resource_prefix, local.elasticache_subnets[count.index].availability_zone) }), var.tags)
  )
}

resource "aws_elasticache_subnet_group" "elasticache" {
  count = length(aws_subnet.elasticache) > 0 ? 1 : 0
  # if a custom subnet group name is defined, set resource tag 'Name' to the custom name, else, generate one based on Coalfire's naming convention
  name        = var.elasticache_subnet_group_name != null ? var.elasticache_subnet_group_name : var.resource_prefix
  description = "ElastiCache subnet group for ${var.resource_prefix}"
  subnet_ids  = aws_subnet.elasticache[*].id
}

######################################################
# intra subnets - private subnet without NAT gateway #
######################################################
resource "aws_subnet" "intra" {
  count             = length(local.intra_subnets) > 0 ? length(local.intra_subnets) : 0
  vpc_id            = local.vpc_id
  cidr_block        = local.intra_subnets[count.index].cidr
  availability_zone = local.intra_subnets[count.index].availability_zone
  tags = (
    # if a custom subnet name is defined, set resource tag 'Name' to the custom name, else, generate a name based on Coalfire's naming convention
    local.intra_subnets[count.index].custom_name != null ?
    merge(tomap({ "Name" = "${local.intra_subnets[count.index].custom_name}" }), var.tags) :
    merge(tomap({ "Name" = format("%s-${local.intra_subnets[count.index].tag}-%s", var.resource_prefix, local.intra_subnets[count.index].availability_zone) }), var.tags)
  )
}
