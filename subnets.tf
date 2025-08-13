################
# Firewall subnet
################

# resource "aws_subnet" "firewall" {
#   count = length(var.firewall_subnets) > 0 ? length(var.firewall_subnets) : 0

#   vpc_id = local.vpc_id
#   cidr_block = var.firewall_subnets[
#     count.index
#   ]
#   availability_zone = element(var.azs, count.index)

#   tags = merge(tomap({
#     "Name" = format("%s-${lower(var.firewall_subnet_suffix)}-%s", var.name, element(var.azs, count.index))
#   }), var.tags)
# }

resource "aws_subnet" "firewall" {
  for_each          = local.firewall_subnets
  vpc_id            = local.vpc_id
  cidr_block        = each.cidr
  availability_zone = each.availability_zone
  tags = merge(tomap({
    "Name" = "${each.name}"
  }), var.tags)
}

# ################
# # Public subnet
# ################
# resource "aws_subnet" "public" {
#   #checkov:skip=CKV_AWS_130: "Ensure VPC subnets do not assign public IP by default" - This is a public subet.
#   count = length(var.public_subnets) > 0 && (!var.one_nat_gateway_per_az || length(var.public_subnets) >= length(var.azs)) ? length(var.public_subnets) : 0

#   vpc_id = local.vpc_id
#   cidr_block = var.public_subnets[
#     count.index
#   ]
#   availability_zone       = element(var.azs, count.index)
#   map_public_ip_on_launch = var.map_public_ip_on_launch

#   tags = merge(tomap({
#     "Name" = format("%s-${lower(var.public_subnet_suffix)}-%s", var.name, element(var.azs, count.index))
#   }), var.tags, var.public_eks_tags)
# }

resource "aws_subnet" "public" {
  #checkov:skip=CKV_AWS_130: "Ensure VPC subnets do not assign public IP by default" - This is a public subet.
  for_each                = local.public_subnets
  vpc_id                  = local.vpc_id
  cidr_block              = each.cidr
  availability_zone       = each.availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags = merge(tomap({
    "Name" = "${each.name}"
  }), var.tags, var.public_eks_tags)
}


# #################
# # Private subnet
# #################
# resource "aws_subnet" "private" {
#   count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

#   vpc_id = local.vpc_id
#   cidr_block = var.private_subnets[
#     count.index
#   ]
#   availability_zone = element(var.azs, count.index)

#   tags = merge(tomap({
#     "Name" = format("%s-${lower(var.private_subnet_tags[count.index])}-%s", var.name, element(var.azs, count.index))
#   }), var.tags, var.private_eks_tags)
# }

resource "aws_subnet" "private" {
  for_each          = local.private_subnets
  vpc_id            = local.vpc_id
  cidr_block        = each.cidr
  availability_zone = each.availability_zone
  tags = merge(tomap({
    "Name" = "${each.name}"
  }), var.tags, var.private_eks_tags)
}


# #################
# # TGW subnet
# #################
# resource "aws_subnet" "tgw" {
#   count = length(var.tgw_subnets) > 0 ? length(var.tgw_subnets) : 0

#   vpc_id = local.vpc_id
#   cidr_block = var.tgw_subnets[
#     count.index
#   ]
#   availability_zone = element(var.azs, count.index)

#   tags = merge(tomap({
#     "Name" = format("%s-${lower(var.tgw_subnet_tags[count.index])}-%s", var.name, element(var.azs, count.index))
#   }), var.tags)
# }

resource "aws_subnet" "tgw" {
  for_each          = local.tgw_subnets
  vpc_id            = local.vpc_id
  cidr_block        = each.cidr
  availability_zone = each.availability_zone
  tags = merge(tomap({
    "Name" = "${each.name}"
  }), var.tags)
}

# ##################
# # Database subnet
# ##################
# resource "aws_subnet" "database" {
#   count = length(var.database_subnets) > 0 ? length(var.database_subnets) : 0

#   vpc_id = local.vpc_id
#   cidr_block = var.database_subnets[
#     count.index
#   ]
#   availability_zone = element(var.azs, count.index)

#   tags = merge(tomap({
#     "Name" = format("%s-${var.database_subnet_suffix}-%s", var.name, element(var.azs, count.index))
#   }), var.database_subnet_tags, var.tags)
# }

resource "aws_subnet" "database" {
  for_each          = local.database_subnets
  vpc_id            = local.vpc_id
  cidr_block        = each.cidr
  availability_zone = each.availability_zone
  tags = merge(tomap({
    "Name" = "${each.name}"
  }), var.database_subnet_tags, var.tags)
}

# resource "aws_db_subnet_group" "database" {
#   count = length(var.database_subnets) > 0 && var.create_database_subnet_group ? 1 : 0

#   name        = "${lower(var.name)}-backend"
#   description = "Database subnet group for ${var.name}"
#   subnet_ids  = aws_subnet.database[*].id

#   tags = merge(tomap({
#     "Name" = format("%s", var.name)
#   }), var.tags, var.database_subnet_group_tags)
# }

resource "aws_db_subnet_group" "database" {
  count       = length(local.database_subnets) > 0 && var.create_database_subnet_group ? 1 : 0
  name        = local.database_subnet_group_name
  description = "Database subnet group for ${var.name}"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(tomap({
    "Name" = format("%s", var.name)
  }), var.tags, var.database_subnet_group_tags)
}

##################
# Redshift subnet
##################
# resource "aws_subnet" "redshift" {
#   count = length(var.redshift_subnets) > 0 ? length(var.redshift_subnets) : 0

#   vpc_id = local.vpc_id
#   cidr_block = var.redshift_subnets[
#     count.index
#   ]
#   availability_zone = element(var.azs, count.index)

#   tags = merge(tomap({
#     "Name" = format("%s-${var.redshift_subnet_suffix}-%s", var.name, element(var.azs, count.index))
#   }), var.tags)
# }

resource "aws_subnet" "redshift" {
  for_each          = local.redshift_subnets
  vpc_id            = local.vpc_id
  cidr_block        = each.cidr
  availability_zone = each.availability_zone
  tags = merge(tomap({
    "Name" = "${each.name}"
  }), var.tags)
}

# resource "aws_redshift_subnet_group" "redshift" {
#   count = length(var.redshift_subnets) > 0 ? 1 : 0

#   name        = var.name
#   description = "Redshift subnet group for ${var.name}"
#   subnet_ids = [
#     aws_subnet.redshift[*].id
#   ]

#   tags = merge(tomap({
#     "Name" = format("%s", var.name)
#   }), var.tags, var.redshift_subnet_group_tags)
# }

resource "aws_redshift_subnet_group" "redshift" {
  count       = length(local.redshift_subnets) > 0 ? 1 : 0
  name        = local.redshift_subnet_group_name
  description = "Redshift subnet group for ${var.name}"
  subnet_ids = [
    aws_subnet.redshift[*].id
  ]
  tags = merge(tomap({
    "Name" = format("%s", var.name)
  }), var.tags, var.redshift_subnet_group_tags)
}

#####################
# ElastiCache subnet
#####################
# resource "aws_subnet" "elasticache" {
#   count = length(var.elasticache_subnets) > 0 ? length(var.elasticache_subnets) : 0

#   vpc_id = local.vpc_id
#   cidr_block = var.elasticache_subnets[
#     count.index
#   ]
#   availability_zone = element(var.azs, count.index)

#   tags = merge(tomap({
#     "Name" = format("%s-${var.elasticache_subnet_suffix}-%s", var.name, element(var.azs, count.index))
#   }), var.tags)
# }

resource "aws_subnet" "elasticache" {
  for_each          = local.elasticache_subnets
  vpc_id            = local.vpc_id
  cidr_block        = each.cidr
  availability_zone = each.availability_zone
  tags = merge(tomap({
    "Name" = "${each.name}"
  }), var.tags)
}

resource "aws_elasticache_subnet_group" "elasticache" {
  count       = length(var.elasticache_subnets) > 0 ? 1 : 0
  name        = local.elasticache_subnet_group_name
  description = "ElastiCache subnet group for ${var.name}"
  subnet_ids  = aws_subnet.elasticache[*].id
}

#####################################################
# intra subnets - private subnet without NAT gateway
#####################################################
resource "aws_subnet" "intra" {
  for_each          = local.intra_subnets
  vpc_id            = local.vpc_id
  cidr_block        = each.cidr
  availability_zone = each.availability_zone
  tags = merge(tomap({
    "Name" = "${each.name}"
  }), var.tags)
}
