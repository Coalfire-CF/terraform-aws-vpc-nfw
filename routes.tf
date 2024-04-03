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

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

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
  depends_on = [ module.aws_network_firewall ]
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

resource "aws_route" "public_custom" {
  count = length(var.public_custom_routes) > 0 && !var.deploy_aws_nfw ? length(var.public_custom_routes) * length(aws_route_table.public) : 0

  # Math result should mirror the number of subnets/route tables
  # The desired end goal if given 2 custom routes and 3 subnets/AZs/Route Table is to create a route for each table
  # E.g. if 3 AZs/subnets, then the result of math/logic should be 0, 1, 2, 0, 1, 2
  # Because the element() function automatically wraps around the index (start from 0 if greater than list size), we combine it with the index function to ensure correct order
  route_table_id = aws_route_table.public[index(aws_route_table.public, element(aws_route_table.public, count.index))].id

  destination_cidr_block     = lookup(var.public_custom_routes[floor(count.index / length(aws_route_table.public))], "destination_cidr_block", null)
  destination_prefix_list_id = lookup(var.public_custom_routes[floor(count.index / length(aws_route_table.public))], "destination_prefix_list_id", null)

  network_interface_id = lookup(var.public_custom_routes[floor(count.index / length(aws_route_table.public))], "network_interface_id", null)
  gateway_id           = var.public_custom_routes[floor(count.index / length(aws_route_table.public))]["internet_route"] ? aws_internet_gateway.this[0].id : null
  transit_gateway_id   = lookup(var.public_custom_routes[floor(count.index / length(aws_route_table.public))], "transit_gateway_id", null)

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "nfw_public_custom" {
  count = length(var.public_custom_routes) > 0 && var.deploy_aws_nfw ? length(var.public_custom_routes) * length(aws_route_table.public) : 0

  # Math result should mirror the number of subnets/route tables
  # The desired end goal if given 2 custom routes and 3 subnets/AZs/Route Table is to create a route for each table
  # E.g. if 3 AZs/subnets, then the result of math/logic should be 0, 1, 2, 0, 1, 2
  # Because the element() function automatically wraps around the index (start from 0 if greater than list size), we combine it with the index function to ensure correct order
  route_table_id = aws_route_table.public[index(aws_route_table.public, element(aws_route_table.public, count.index))].id

  destination_cidr_block     = lookup(var.public_custom_routes[floor(count.index / length(aws_route_table.public))], "destination_cidr_block", null)
  destination_prefix_list_id = lookup(var.public_custom_routes[floor(count.index / length(aws_route_table.public))], "destination_prefix_list_id", null)

  vpc_endpoint_id      = var.public_custom_routes[floor(count.index / length(aws_route_table.public))]["internet_route"] ? module.aws_network_firewall[0].endpoint_id[index(aws_route_table.public, element(aws_route_table.public, count.index))] : null

  timeouts {
    create = "5m"
  }
}

#################
# Private routes
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

resource "aws_route" "private_custom" {
  count = length(var.private_custom_routes) > 0 ? length(var.private_custom_routes) * length(aws_route_table.private) : 0

  # Math result should mirror the number of subnets/route tables
  # The desired end goal if given 2 custom routes and 3 subnets/AZs/Route Table is to create a route for each table
  # E.g. if 3 AZs/subnets, then the result of math/logic should be 0, 1, 2, 0, 1, 2
  # Because the element() function automatically wraps around the index (start from 0 if greater than list size), we combine it with the index function to ensure correct order
  route_table_id = aws_route_table.private[index(aws_route_table.private, element(aws_route_table.private, count.index))].id

  destination_cidr_block     = lookup(var.private_custom_routes[floor(count.index / length(aws_route_table.private))], "destination_cidr_block", null)
  destination_prefix_list_id = lookup(var.private_custom_routes[floor(count.index / length(aws_route_table.private))], "destination_prefix_list_id", null)

  network_interface_id = lookup(var.private_custom_routes[floor(count.index / length(aws_route_table.private))], "network_interface_id", null)
  transit_gateway_id   = lookup(var.private_custom_routes[floor(count.index / length(aws_route_table.private))], "transit_gateway_id", null)
  vpc_endpoint_id      = lookup(var.private_custom_routes[floor(count.index / length(aws_route_table.private))], "vpc_endpoint_id", null)

  timeouts {
    create = "5m"
  }
}

#################
# TGW routes
#################
resource "aws_route_table" "tgw" {
  count = local.max_subnet_length > 0 ? length(var.tgw_subnets) : 0

  vpc_id = local.vpc_id

  tags = merge(tomap({
    "Name" = (var.single_nat_gateway ? "${var.name}-${var.tgw_subnet_suffix}" : format("%s-${var.tgw_subnet_suffix}-%s-rtb", var.name, element(var.azs, count.index)))
  }), var.tags, var.tgw_route_table_tags)

  lifecycle {
    # When attaching VPN gateways it is common to define aws_vpn_gateway_route_propagation
    # resources that manipulate the attributes of the routing table (typically for the tgw subnets)
    ignore_changes = [propagating_vgws]
  }
}

resource "aws_route" "tgw_custom" {
  count = length(var.tgw_custom_routes) > 0 ? length(var.tgw_custom_routes) * length(aws_route_table.tgw) : 0

  # Math result should mirror the number of subnets/route tables
  # The desired end goal if given 2 custom routes and 3 subnets/AZs/Route Table is to create a route for each table
  # E.g. if 3 AZs/subnets, then the result of math/logic should be 0, 1, 2, 0, 1, 2
  # Because the element() function automatically wraps around the index (start from 0 if greater than list size), we combine it with the index function to ensure correct order
  route_table_id = aws_route_table.tgw[index(aws_route_table.tgw, element(aws_route_table.tgw, count.index))].id

  destination_cidr_block     = lookup(var.tgw_custom_routes[floor(count.index / length(aws_route_table.tgw))], "destination_cidr_block", null)
  destination_prefix_list_id = lookup(var.tgw_custom_routes[floor(count.index / length(aws_route_table.tgw))], "destination_prefix_list_id", null)

  network_interface_id = lookup(var.tgw_custom_routes[floor(count.index / length(aws_route_table.tgw))], "network_interface_id", null)
  transit_gateway_id   = lookup(var.tgw_custom_routes[floor(count.index / length(aws_route_table.tgw))], "transit_gateway_id", null)
  vpc_endpoint_id      = lookup(var.tgw_custom_routes[floor(count.index / length(aws_route_table.tgw))], "vpc_endpoint_id", null)

  timeouts {
    create = "5m"
  }
}

#################
# Firewall routes
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

resource "aws_route" "firewall_custom" {
  count = length(var.firewall_custom_routes) > 0 ? length(var.firewall_custom_routes) * length(aws_route_table.firewall) : 0

  # Math result should mirror the number of subnets/route tables
  # The desired end goal if given 2 custom routes and 3 subnets/AZs/Route Table is to create a route for each table
  # E.g. if 3 AZs/subnets, then the result of math/logic should be 0, 1, 2, 0, 1, 2
  # Because the element() function automatically wraps around the index (start from 0 if greater than list size), we combine it with the index function to ensure correct order
  route_table_id = aws_route_table.firewall[index(aws_route_table.firewall, element(aws_route_table.firewall, count.index))].id

  destination_cidr_block     = lookup(var.firewall_custom_routes[floor(count.index / length(aws_route_table.firewall))], "destination_cidr_block", null)
  destination_prefix_list_id = lookup(var.firewall_custom_routes[floor(count.index / length(aws_route_table.firewall))], "destination_prefix_list_id", null)

  network_interface_id = lookup(var.firewall_custom_routes[floor(count.index / length(aws_route_table.firewall))], "network_interface_id", null)
  gateway_id           = var.firewall_custom_routes[floor(count.index / length(aws_route_table.firewall))]["internet_route"] ? aws_internet_gateway.this[0].id : null
  transit_gateway_id   = lookup(var.firewall_custom_routes[floor(count.index / length(aws_route_table.firewall))], "transit_gateway_id", null)
  vpc_endpoint_id      = lookup(var.firewall_custom_routes[floor(count.index / length(aws_route_table.firewall))], "vpc_endpoint_id", null)

  timeouts {
    create = "5m"
  }
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

resource "aws_route" "database_custom" {
  count = var.create_database_subnet_route_table && length(var.database_custom_routes) > 0 ? length(var.database_custom_routes) * length(aws_route_table.database) : 0

  # Math result should mirror the number of subnets/route tables
  # The desired end goal if given 2 custom routes and 3 subnets/AZs/Route Table is to create a route for each table
  # E.g. if 3 AZs/subnets, then the result of math/logic should be 0, 1, 2, 0, 1, 2
  # Because the element() function automatically wraps around the index (start from 0 if greater than list size), we combine it with the index function to ensure correct order
  route_table_id = aws_route_table.database[index(aws_route_table.database, element(aws_route_table.database, count.index))].id

  destination_cidr_block     = lookup(var.database_custom_routes[floor(count.index / length(aws_route_table.database))], "destination_cidr_block", null)
  destination_prefix_list_id = lookup(var.database_custom_routes[floor(count.index / length(aws_route_table.database))], "destination_prefix_list_id", null)

  network_interface_id = lookup(var.database_custom_routes[floor(count.index / length(aws_route_table.database))], "network_interface_id", null)
  transit_gateway_id   = lookup(var.database_custom_routes[floor(count.index / length(aws_route_table.database))], "transit_gateway_id", null)
  vpc_endpoint_id      = lookup(var.database_custom_routes[floor(count.index / length(aws_route_table.database))], "vpc_endpoint_id", null)

  timeouts {
    create = "5m"
  }
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

resource "aws_route" "redshift_custom" {
  count = var.create_redshift_subnet_route_table && length(var.redshift_custom_routes) > 0 ? length(var.redshift_custom_routes) * length(aws_route_table.redshift) : 0

  # Math result should mirror the number of subnets/route tables
  # The desired end goal if given 2 custom routes and 3 subnets/AZs/Route Table is to create a route for each table
  # E.g. if 3 AZs/subnets, then the result of math/logic should be 0, 1, 2, 0, 1, 2
  # Because the element() function automatically wraps around the index (start from 0 if greater than list size), we combine it with the index function to ensure correct order
  route_table_id = aws_route_table.redshift[index(aws_route_table.redshift, element(aws_route_table.redshift, count.index))].id

  destination_cidr_block     = lookup(var.redshift_custom_routes[floor(count.index / length(aws_route_table.redshift))], "destination_cidr_block", null)
  destination_prefix_list_id = lookup(var.redshift_custom_routes[floor(count.index / length(aws_route_table.redshift))], "destination_prefix_list_id", null)

  network_interface_id = lookup(var.redshift_custom_routes[floor(count.index / length(aws_route_table.redshift))], "network_interface_id", null)
  transit_gateway_id   = lookup(var.redshift_custom_routes[floor(count.index / length(aws_route_table.redshift))], "transit_gateway_id", null)
  vpc_endpoint_id      = lookup(var.redshift_custom_routes[floor(count.index / length(aws_route_table.redshift))], "vpc_endpoint_id", null)

  timeouts {
    create = "5m"
  }
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

resource "aws_route" "elasticache_custom" {
  count = var.create_elasticache_subnet_route_table && length(var.elasticache_custom_routes) > 0 ? length(var.elasticache_custom_routes) * length(aws_route_table.elasticache) : 0

  # Math result should mirror the number of subnets/route tables
  # The desired end goal if given 2 custom routes and 3 subnets/AZs/Route Table is to create a route for each table
  # E.g. if 3 AZs/subnets, then the result of math/logic should be 0, 1, 2, 0, 1, 2
  # Because the element() function automatically wraps around the index (start from 0 if greater than list size), we combine it with the index function to ensure correct order
  route_table_id = aws_route_table.elasticache[index(aws_route_table.elasticache, element(aws_route_table.elasticache, count.index))].id

  destination_cidr_block     = lookup(var.elasticache_custom_routes[floor(count.index / length(aws_route_table.elasticache))], "destination_cidr_block", null)
  destination_prefix_list_id = lookup(var.elasticache_custom_routes[floor(count.index / length(aws_route_table.elasticache))], "destination_prefix_list_id", null)

  network_interface_id = lookup(var.elasticache_custom_routes[floor(count.index / length(aws_route_table.elasticache))], "network_interface_id", null)
  transit_gateway_id   = lookup(var.elasticache_custom_routes[floor(count.index / length(aws_route_table.elasticache))], "transit_gateway_id", null)
  vpc_endpoint_id      = lookup(var.elasticache_custom_routes[floor(count.index / length(aws_route_table.elasticache))], "vpc_endpoint_id", null)

  timeouts {
    create = "5m"
  }
}

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

resource "aws_route" "intra_custom" {
  count = length(var.intra_custom_routes) > 0 ? length(var.intra_custom_routes) * length(aws_route_table.intra) : 0

  # Math result should mirror the number of subnets/route tables
  # The desired end goal if given 2 custom routes and 3 subnets/AZs/Route Table is to create a route for each table
  # E.g. if 3 AZs/subnets, then the result of math/logic should be 0, 1, 2, 0, 1, 2
  # Because the element() function automatically wraps around the index (start from 0 if greater than list size), we combine it with the index function to ensure correct order
  route_table_id = aws_route_table.intra[index(aws_route_table.intra, element(aws_route_table.intra, count.index))].id

  destination_cidr_block     = lookup(var.intra_custom_routes[floor(count.index / length(aws_route_table.intra))], "destination_cidr_block", null)
  destination_prefix_list_id = lookup(var.intra_custom_routes[floor(count.index / length(aws_route_table.intra))], "destination_prefix_list_id", null)

  network_interface_id = lookup(var.intra_custom_routes[floor(count.index / length(aws_route_table.intra))], "network_interface_id", null)
  transit_gateway_id   = lookup(var.intra_custom_routes[floor(count.index / length(aws_route_table.intra))], "transit_gateway_id", null)
  vpc_endpoint_id      = lookup(var.intra_custom_routes[floor(count.index / length(aws_route_table.intra))], "vpc_endpoint_id", null)

  timeouts {
    create = "5m"
  }
}

##############
# NAT Gateway
##############

resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)

  timeouts {
    create = "5m"
  }
}


##########################
# Route table association
##########################
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets) > 0 ? length(var.private_subnets) : 0

  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, (var.single_nat_gateway ? 0 : count.index))
}

resource "aws_route_table_association" "tgw" {
  count = length(var.tgw_subnets) > 0 ? length(var.tgw_subnets) : 0

  subnet_id      = element(aws_subnet.tgw[*].id, count.index)
  route_table_id = element(aws_route_table.tgw[*].id, (var.single_nat_gateway ? 0 : count.index))
}

resource "aws_route_table_association" "firewall" {
  count = var.deploy_aws_nfw ? length(var.firewall_subnets) : 0

  subnet_id      = element(aws_subnet.firewall[*].id, count.index)
  route_table_id = element(aws_route_table.firewall[*].id, (var.single_nat_gateway ? 0 : count.index))
}

resource "aws_route_table_association" "database" {
  count = length(var.database_subnets) > 0 ? length(var.database_subnets) : 0

  subnet_id      = element(aws_subnet.database[*].id, count.index)
  route_table_id = element(coalescelist(aws_route_table.database[*].id, aws_route_table.private[*].id), (var.single_nat_gateway || var.create_database_subnet_route_table ? 0 : count.index))
}

resource "aws_route_table_association" "redshift" {
  count = length(var.redshift_subnets) > 0 ? length(var.redshift_subnets) : 0

  subnet_id      = element(aws_subnet.redshift[*].id, count.index)
  route_table_id = element(coalescelist(aws_route_table.redshift[*].id, aws_route_table.private[*].id), (var.single_nat_gateway || var.create_redshift_subnet_route_table ? 0 : count.index))
}

resource "aws_route_table_association" "elasticache" {
  count = length(var.elasticache_subnets) > 0 ? length(var.elasticache_subnets) : 0

  subnet_id      = element(aws_subnet.elasticache[*].id, count.index)
  route_table_id = element(coalescelist(aws_route_table.elasticache[*].id, aws_route_table.private[*].id), (var.single_nat_gateway || var.create_elasticache_subnet_route_table ? 0 : count.index))
}

resource "aws_route_table_association" "intra" {
  count = length(var.intra_subnets) > 0 ? length(var.intra_subnets) : 0

  subnet_id      = element(aws_subnet.intra[*].id, count.index)
  route_table_id = element(aws_route_table.intra[*].id, 0)
}

resource "aws_route_table_association" "public" {
  count = var.deploy_aws_nfw ? 0 : length(var.public_subnets)

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public[0].id

  depends_on = [
    aws_subnet.public
  ]
}

resource "aws_route_table_association" "nfw_public" {
  count = var.deploy_aws_nfw ? length(var.public_subnets) : 0

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public[count.index].id

  depends_on = [
    aws_subnet.public
  ]
}
