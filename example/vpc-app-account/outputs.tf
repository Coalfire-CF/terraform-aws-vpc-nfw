output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.prod_vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.prod_vpc.vpc_cidr_block
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.prod_vpc.default_security_group_id
}

output "default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = module.prod_vpc.default_network_acl_id
}

output "default_route_table_id" {
  description = "The ID of the default route table"
  value       = module.prod_vpc.default_route_table_id
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = module.prod_vpc.vpc_instance_tenancy
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = module.prod_vpc.vpc_enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = module.prod_vpc.vpc_enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = module.prod_vpc.vpc_main_route_table_id
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = module.prod_vpc.vpc_secondary_cidr_blocks
}

output "firewall_subnets" {
  description = "List of IDs of firewall subnets"
  value       = module.prod_vpc.firewall_subnets
}

output "firewall_subnets_cidr_blocks" {
  description = "List of cidr_blocks of firewall subnets"
  value       = module.prod_vpc.firewall_subnets_cidr_blocks
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.prod_vpc.private_subnets
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value       = module.prod_vpc.private_subnets_cidr_blocks
}

output "tgw_subnets" {
  description = "List of IDs of tgw subnets"
  value       = module.prod_vpc.tgw_subnets
}

output "tgw_subnets_cidr_blocks" {
  description = "List of cidr_blocks of tgw subnets"
  value       = module.prod_vpc.tgw_subnets_cidr_blocks
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.prod_vpc.public_subnets
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value       = module.prod_vpc.public_subnets_cidr_blocks
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = module.prod_vpc.database_subnets
}

output "database_subnets_cidr_blocks" {
  description = "List of cidr_blocks of database subnets"
  value       = module.prod_vpc.database_subnets_cidr_blocks
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value       = module.prod_vpc.database_subnet_group

}

output "redshift_subnets" {
  description = "List of IDs of redshift subnets"
  value       = module.prod_vpc.redshift_subnets
}

output "redshift_subnets_cidr_blocks" {
  description = "List of cidr_blocks of redshift subnets"
  value       = module.prod_vpc.redshift_subnets_cidr_blocks
}

output "redshift_subnet_group" {
  description = "ID of redshift subnet group"
  value       = module.prod_vpc.redshift_subnet_group

}

output "elasticache_subnets" {
  description = "List of IDs of elasticache subnets"
  value       = module.prod_vpc.elasticache_subnets
}

output "elasticache_subnets_cidr_blocks" {
  description = "List of cidr_blocks of elasticache subnets"
  value       = module.prod_vpc.elasticache_subnets_cidr_blocks
}

output "intra_subnets" {
  description = "List of IDs of intra subnets"
  value       = module.prod_vpc.intra_subnets
}

output "intra_subnets_cidr_blocks" {
  description = "List of cidr_blocks of intra subnets"
  value       = module.prod_vpc.intra_subnets_cidr_blocks
}

output "elasticache_subnet_group" {
  description = "ID of elasticache subnet group"
  value       = module.prod_vpc.elasticache_subnet_group

}

output "elasticache_subnet_group_name" {
  description = "Name of elasticache subnet group"
  value       = module.prod_vpc.elasticache_subnet_group_name

}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = module.prod_vpc.private_route_table_ids
}

output "tgw_route_table_ids" {
  description = "List of IDs of tgw route tables"
  value       = module.prod_vpc.tgw_route_table_ids
}

output "firewall_route_table_ids" {
  description = "List of IDs of firewall route tables"
  value       = module.prod_vpc.firewall_route_table_ids
}

output "aws_nfw_endpoint_ids" {
  description = "List of IDs of AWS NFW endpoints"
  value       = module.prod_vpc.aws_nfw_endpoint_ids
}
output "redshift_route_table_ids" {
  description = "List of IDs of redshift route tables"
  value       = module.prod_vpc.redshift_route_table_ids

}

output "elasticache_route_table_ids" {
  description = "List of IDs of elasticache route tables"
  value       = module.prod_vpc.elasticache_route_table_ids

}

output "intra_route_table_ids" {
  description = "List of IDs of intra route tables"
  value       = module.prod_vpc.intra_route_table_ids
}

output "nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = module.prod_vpc.nat_ids
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = module.prod_vpc.nat_public_ips
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = module.prod_vpc.natgw_ids
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = module.prod_vpc.igw_id
}

output "vgw_id" {
  description = "The ID of the VPN Gateway"
  value       = module.prod_vpc.vgw_id
}

output "default_vpc_id" {
  description = "The ID of the VPC"
  value       = module.prod_vpc.default_vpc_id
}

output "default_vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.prod_vpc.default_vpc_cidr_block

}

output "default_vpc_default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value       = module.prod_vpc.default_vpc_default_security_group_id

}

output "default_vpc_default_network_acl_id" {
  description = "The ID of the default network ACL"
  value       = module.prod_vpc.default_vpc_default_network_acl_id
}

output "default_vpc_default_route_table_id" {
  description = "The ID of the default route table"
  value       = module.prod_vpc.default_vpc_default_route_table_id

}

output "default_vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value       = module.prod_vpc.default_vpc_instance_tenancy

}

output "default_vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value       = module.prod_vpc.default_vpc_enable_dns_support

}

output "default_vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value       = module.prod_vpc.default_vpc_enable_dns_hostnames

}

output "default_vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value       = module.prod_vpc.default_vpc_main_route_table_id
}

output "vpc_endpoints" {
  description = "Map of VPC endpoint IDs"
  value       = module.prod_vpc.vpc_endpoints
}

output "vpc_endpoint_security_groups" {
  description = "Map of security group IDs created for VPC endpoints"
  value       = module.prod_vpc.vpc_endpoint_security_groups
}