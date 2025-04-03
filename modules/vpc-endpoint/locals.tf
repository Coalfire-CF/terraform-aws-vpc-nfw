locals {
  gateway_endpoints = {
    for k, v in var.vpc_endpoints :
      k => v if lookup(v, "service_type", "Gateway") == "Gateway"
  }

  interface_endpoints = {
    for k, v in var.vpc_endpoints :
      k => v if lookup(v, "service_type", "") == "Interface"
  }

  # Build a map using only static keys that can be resolved at plan time
  route_table_association_map = {
    for pair in setproduct(
      [for key, ep in var.vpc_endpoints : key if lookup(ep, "service_type", "") == "Gateway"],
      var.private_route_table_ids
    ) :
    "${pair[0]}-${pair[1]}" => {
      endpoint_key    = pair[0]
      route_table_id  = pair[1]
    }
    if var.create_vpc_endpoints && var.associate_with_private_route_tables
  }


  # Get all security group IDs created for VPC endpoints
  endpoint_sg_ids = {
    for sg_key, sg in aws_security_group.endpoint_sg : sg_key => sg.id
  }
   # List of all security group IDs for common use
  all_endpoint_sg_ids = values(local.endpoint_sg_ids)

  # Flatten ingress rules (keep as-is, not changing)
  flattened_ingress_rules = flatten([
    for sg_key, sg in var.vpc_endpoint_security_groups : [
      for rule_idx, rule in try(sg.ingress_rules, []) : {
        sg_key    = sg_key
        rule_idx  = rule_idx
        rule      = rule
        cidr_type = length(try(rule.cidr_blocks, [])) > 0 ? "ipv4" : (
          length(try(rule.ipv6_cidr_blocks, [])) > 0 ? "ipv6" : (
            length(try(rule.security_groups, [])) > 0 ? "sg" : null
          )
        )
      }
    ]
  ])

  # Flatten egress rules (keep as-is, not changing)
  flattened_egress_rules = flatten([
    for sg_key, sg in var.vpc_endpoint_security_groups : [
      for rule_idx, rule in try(sg.egress_rules, []) : {
        sg_key    = sg_key
        rule_idx  = rule_idx
        rule      = rule
        cidr_type = length(try(rule.cidr_blocks, [])) > 0 ? "ipv4" : (
          length(try(rule.ipv6_cidr_blocks, [])) > 0 ? "ipv6" : (
            length(try(rule.security_groups, [])) > 0 ? "sg" : null
          )
        )
      }
    ]
  ])
}
