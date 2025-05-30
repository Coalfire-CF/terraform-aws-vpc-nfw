# Get VPC endpoint service details if needed
data "aws_vpc_endpoint_service" "this" {
  for_each = var.create_vpc_endpoints ? {
    for endpoint_key, endpoint in var.vpc_endpoints :
      endpoint_key => endpoint if lookup(endpoint, "service_name", null) == null
  } : {}

  service = each.key

  # If we're looking up the service, we need to filter by the right service type
  filter {
    name   = "service-type"
    values = [lookup(var.vpc_endpoints[each.key], "service_type", "Gateway")]
  }
}

# Create security groups for VPC endpoints
resource "aws_security_group" "endpoint_sg" {
  for_each = var.create_vpc_endpoints ? var.vpc_endpoint_security_groups : {}

  name        = each.value.name
  description = each.value.description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    try(each.value.tags, {}),
    {
      Name = each.value.name
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Create ingress rules for security groups
resource "aws_vpc_security_group_ingress_rule" "ingress" {
  for_each = {
    for idx, rule in local.flattened_ingress_rules :
    "${rule.sg_key}_ingress_${rule.rule_idx}_${rule.cidr_type}" => rule
    if rule.cidr_type != null
  }

  security_group_id = aws_security_group.endpoint_sg[each.value.sg_key].id

  from_port   = each.value.rule.from_port
  to_port     = each.value.rule.to_port
  ip_protocol = each.value.rule.protocol
  description = try(each.value.rule.description, null)

  # Conditionally set CIDR or security group references
  cidr_ipv4 = (
    each.value.cidr_type == "ipv4" && length(try(each.value.rule.cidr_blocks, [])) > 0
    ? each.value.rule.cidr_blocks[0]
    : null
  )

  cidr_ipv6 = (
    each.value.cidr_type == "ipv6" && length(try(each.value.rule.ipv6_cidr_blocks, [])) > 0
    ? each.value.rule.ipv6_cidr_blocks[0]
    : null
  )

  referenced_security_group_id = (
    each.value.cidr_type == "sg" && length(try(each.value.rule.security_groups, [])) > 0
    ? each.value.rule.security_groups[0]
    : null
  )
}

# Create egress rules for security groups
resource "aws_vpc_security_group_egress_rule" "egress" {
  for_each = {
    for idx, rule in local.flattened_egress_rules :
    "${rule.sg_key}_egress_${rule.rule_idx}_${rule.cidr_type}" => rule
    if rule.cidr_type != null
  }

  security_group_id = aws_security_group.endpoint_sg[each.value.sg_key].id

  from_port   = each.value.rule.protocl == "-1" ? null : each.value.rule.from_port
  to_port     = each.value.rule.protocl == "-1" ? null : each.value.rule.to_port
  ip_protocol = each.value.rule.protocol
  description = try(each.value.rule.description, null)

  # Conditionally set CIDR or security group references
  cidr_ipv4 = (
    each.value.cidr_type == "ipv4" && length(try(each.value.rule.cidr_blocks, [])) > 0
    ? each.value.rule.cidr_blocks[0]
    : null
  )

  cidr_ipv6 = (
    each.value.cidr_type == "ipv6" && length(try(each.value.rule.ipv6_cidr_blocks, [])) > 0
    ? each.value.rule.ipv6_cidr_blocks[0]
    : null
  )

  referenced_security_group_id = (
    each.value.cidr_type == "sg" && length(try(each.value.rule.security_groups, [])) > 0
    ? each.value.rule.security_groups[0]
    : null
  )
}

# Create VPC endpoints
resource "aws_vpc_endpoint" "this" {
  for_each = var.create_vpc_endpoints ? var.vpc_endpoints : {}

  vpc_id       = var.vpc_id
  service_name = lookup(each.value, "service_name", null) != null ? each.value.service_name : (
  startswith(each.key, "s3") || startswith(each.key, "dynamodb") ?
    "com.amazonaws.${data.aws_region.current.name}.${each.key}" :
    contains(keys(data.aws_vpc_endpoint_service.this), each.key) ?
      data.aws_vpc_endpoint_service.this[each.key].service_name :
      "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  )

  vpc_endpoint_type = lookup(each.value, "service_type", "Gateway")

  # Interface-specific settings
  private_dns_enabled = lookup(each.value, "service_type", "") == "Interface" ? lookup(each.value, "private_dns_enabled", null) : null


  subnet_ids = lookup(each.value, "service_type", "") == "Interface" ? lookup(each.value, "subnet_ids", []) : null

  # Security group IDs for Interface endpoints - always apply all common SGs
  security_group_ids = (
    lookup(each.value, "service_type", "") == "Interface" ?
      concat(
        lookup(each.value, "security_group_ids", []),
        local.all_endpoint_sg_ids
      ) :
      null
  )

  # Gateway-specific settings
  # Setting route tables directly in the endpoint resource for Gateway endpoints
  # This eliminates the need for a separate aws_vpc_endpoint_route_table_association resource
  route_table_ids = lookup(each.value, "service_type", "") == "Gateway" && var.associate_with_private_route_tables ? var.private_route_table_ids : null

  # GatewayLoadBalancer-specific settings
  ip_address_type = lookup(each.value, "service_type", "") == "GatewayLoadBalancer" ? lookup(each.value, "ip_address_type", null) : null

  # Common settings
  auto_accept = lookup(each.value, "auto_accept", false)
  policy      = lookup(each.value, "policy", null)

  tags = merge(
    var.tags,
    lookup(each.value, "tags", {}),
    {
      Name = each.key
    }
  )
}

data "aws_region" "current" {}