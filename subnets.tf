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
  for_each          = { for subnet in local.firewall_subnets : subnet.name => subnet }
  vpc_id            = local.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = each.value.availability_zone
  tags = merge(tomap({
    "Name" = "${each.value.name}"
  }), var.tags)
}
