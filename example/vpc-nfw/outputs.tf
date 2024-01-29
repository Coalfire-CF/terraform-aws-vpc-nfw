output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.mgmt_vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.mgmt_vpc.vpc_cidr_block
}

output "firewall_subnets" {
  description = "List of IDs of firewall subnets"
  value = module.mgmt_vpc.firewall_subnets
}

output "firewall_subnets_cidr_blocks" {
  description = "List of cidr_blocks of firewall subnets"
  value = module.mgmt_vpc.firewall_subnets_cidr_blocks
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value = module.mgmt_vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value = module.mgmt_vpc.private_subnets_cidr_blocks
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.mgmt_vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value = module.mgmt_vpc.public_subnets_cidr_blocks
}


output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.mgmt_vpc.database_subnets
}

output "database_subnets_cidr_blocks" {
  description = "List of cidr_blocks of database subnets"
  value = module.mgmt_vpc.database_subnets_cidr_blocks
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value = module.mgmt_vpc.database_subnet_group
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.mgmt_vpc.private_route_table_ids
}

output "firewall_route_table_ids" {
  description = "List of IDs of firewall route tables"
  value       = module.mgmt_vpc.firewall_route_table_ids
}

output "tgw_route_table_ids" {
  description = "List of IDs of firewall route tables"
  value       = module.mgmt_vpc.tgw_route_table_ids
}


output "aws_nfw_endpoint_ids" {
  description = "List of IDs of AWS NFW endpoints"
  value       = module.mgmt_vpc.aws_nfw_endpoint_ids
}

output "database_route_table_ids" {
  description = "List of IDs of database route tables"
  value       = module.mgmt_vpc.database_route_table_ids
}
