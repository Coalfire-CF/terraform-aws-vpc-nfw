# Create security groups for VPC endpoints
resource "aws_security_group" "endpoint_sg" {
  for_each = var.create_vpc_endpoints ? var.security_groups : {}

  name        = each.value.name
  description = each.value.description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.value.name
    }
  )
}

# Create ingress rules for security groups
resource "aws_security_group_rule" "ingress" {
  for_each = var.create_vpc_endpoints ? {
    for rule in flatten([
      for sg_key, sg in var.security_groups : [
        for rule_idx, rule in sg.ingress_rules : {
          sg_key    = sg_key
          rule_idx  = rule_idx
          rule      = rule
        }
      ]
    ]) : "${rule.sg_key}_ingress_${rule.rule_idx}" => rule
  } : {}

  security_group_id = aws_security_group.endpoint_sg[each.value.sg_key].id
  type              = "ingress"
  from_port         = each.value.rule.from_port
  to_port           = each.value.rule.to_port
  protocol          = each.value.rule.protocol
  description       = each.value.rule.description

  cidr_blocks       = length(each.value.rule.cidr_blocks) > 0 ? each.value.rule.cidr_blocks : null
  ipv6_cidr_blocks  = length(each.value.rule.ipv6_cidr_blocks) > 0 ? each.value.rule.ipv6_cidr_blocks : null
  self              = each.value.rule.self ? true : null

  # Only include security_groups if specified
  security_groups   = length(each.value.rule.security_groups) > 0 ? each.value.rule.security_groups : null
}

# Create egress rules for security groups
resource "aws_security_group_rule" "egress" {
  for_each = var.create_vpc_endpoints ? {
    for rule in flatten([
      for sg_key, sg in var.security_groups : [
        for rule_idx, rule in sg.egress_rules : {
          sg_key    = sg_key
          rule_idx  = rule_idx
          rule      = rule
        }
      ]
    ]) : "${rule.sg_key}_egress_${rule.rule_idx}" => rule
  } : {}

  security_group_id = aws_security_group.endpoint_sg[each.value.sg_key].id
  type              = "egress"
  from_port         = each.value.rule.from_port
  to_port           = each.value.rule.to_port
  protocol          = each.value.rule.protocol
  description       = each.value.rule.description

  cidr_blocks       = length(each.value.rule.cidr_blocks) > 0 ? each.value.rule.cidr_blocks : null
  ipv6_cidr_blocks  = length(each.value.rule.ipv6_cidr_blocks) > 0 ? each.value.rule.ipv6_cidr_blocks : null
  self              = each.value.rule.self ? true : null

  # Only include security_groups if specified
  security_groups   = length(each.value.rule.security_groups) > 0 ? each.value.rule.security_groups : null
}

# Get VPC endpoint service details if needed
data "aws_vpc_endpoint_service" "this" {
  for_each = var.create_vpc_endpoints ? {
    for endpoint_key, endpoint in var.vpc_endpoints :
      endpoint_key => endpoint if endpoint.service_name == null
  } : {}

  service = each.key

  # If we're looking up the service, we need to filter by the right service type
  filter {
    name   = "service-type"
    values = [var.vpc_endpoints[each.key].service_type]
  }
}

locals {
  # Map of endpoint SGs - combine existing SGs with newly created ones
  endpoint_security_groups = {
    for endpoint_key, endpoint in var.vpc_endpoints :
      endpoint_key => concat(
        endpoint.security_group_ids,
        [
          for sg_key, sg in var.security_groups :
            aws_security_group.endpoint_sg[sg_key].id
            if contains(keys(var.security_groups), "${endpoint_key}_sg")
        ]
      )
      if var.create_vpc_endpoints
  }
}

# Create VPC endpoints
resource "aws_vpc_endpoint" "this" {
  for_each = var.create_vpc_endpoints ? var.vpc_endpoints : {}

  vpc_id       = var.vpc_id
  service_name = each.value.service_name != null ? each.value.service_name : (
    startswith(each.key, "s3") || startswith(each.key, "dynamodb") ?
      "com.amazonaws.${data.aws_region.current.name}.${each.key}" :
      data.aws_vpc_endpoint_service.this[each.key].service_name
  )
  vpc_endpoint_type = each.value.service_type

  # Interface-specific settings
  private_dns_enabled = each.value.service_type == "Interface" ? each.value.private_dns_enabled : null
  security_group_ids  = each.value.service_type == "Interface" ? local.endpoint_security_groups[each.key] : null
  subnet_ids          = each.value.service_type == "Interface" ? (
    each.value.subnet_ids != null ? each.value.subnet_ids : var.subnet_ids
  ) : null

  # Gateway-specific settings
  route_table_ids     = each.value.service_type == "Gateway" ? var.route_table_ids : null

  # GatewayLoadBalancer-specific settings
  ip_address_type     = each.value.service_type == "GatewayLoadBalancer" ? each.value.ip_address_type : null

  # Common settings
  auto_accept         = each.value.auto_accept
  policy              = each.value.policy

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

data "aws_region" "current" {}