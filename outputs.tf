output "vpc_id" {
  description = "The ID of the VPC"
  value       = element(concat(aws_vpc.this[*].id, tolist([""])), 0)
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = element(concat(aws_vpc.this[*].cidr_block, tolist([""])), 0)
}

output "default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value = element(concat(aws_vpc.this[*].default_security_group_id, tolist([
    ""
  ])), 0)
}

output "default_network_acl_id" {
  description = "The ID of the default network ACL"
  value = element(concat(aws_vpc.this[*].default_network_acl_id, tolist([
    ""
  ])), 0)
}

output "default_route_table_id" {
  description = "The ID of the default route table"
  value = element(concat(aws_vpc.this[*].default_route_table_id, tolist([
    ""
  ])), 0)
}

output "vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value = element(concat(aws_vpc.this[*].instance_tenancy, tolist([
    ""
  ])), 0)
}

output "vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value = element(concat(aws_vpc.this[*].enable_dns_support, tolist([
    ""
  ])), 0)
}

output "vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value = element(concat(aws_vpc.this[*].enable_dns_hostnames, tolist([
    ""
  ])), 0)
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value = element(concat(aws_vpc.this[*].main_route_table_id, tolist([
    ""
  ])), 0)
}

output "vpc_secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks of the VPC"
  value       = [aws_vpc_ipv4_cidr_block_association.this[*].cidr_block]
}

output "firewall_subnets" {
  description = "List of IDs of firewall subnets"
  value       = zipmap(aws_subnet.firewall[*].tags["Name"], aws_subnet.firewall[*].id)
}

output "firewall_subnets_cidr_blocks" {
  description = "List of cidr_blocks of firewall subnets"
  value = zipmap(aws_subnet.firewall[*].tags["Name"], aws_subnet.firewall[*].cidr_block)
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = zipmap(aws_subnet.private[*].tags["Name"], aws_subnet.private[*].id)
}

output "private_subnets_cidr_blocks" {
  description = "List of cidr_blocks of private subnets"
  value = zipmap(aws_subnet.private[*].tags["Name"], aws_subnet.private[*].cidr_block)
}

output "tgw_subnets" {
  description = "List of IDs of tgw subnets"
  value       = zipmap(aws_subnet.tgw[*].tags["Name"], aws_subnet.tgw[*].id)
}

output "tgw_subnets_cidr_blocks" {
  description = "List of cidr_blocks of tgw subnets"
  value = zipmap(aws_subnet.tgw[*].tags["Name"], aws_subnet.tgw[*].cidr_block)
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = zipmap(aws_subnet.public[*].tags["Name"], aws_subnet.public[*].id)
}

output "public_subnets_cidr_blocks" {
  description = "List of cidr_blocks of public subnets"
  value = zipmap(aws_subnet.public[*].tags["Name"], aws_subnet.public[*].cidr_block)
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = zipmap(aws_subnet.database[*].tags["Name"], aws_subnet.database[*].id)
}

output "database_subnets_cidr_blocks" {
  description = "List of cidr_blocks of database subnets"
  value = zipmap(aws_subnet.database[*].tags["Name"], aws_subnet.database[*].cidr_block)
}

output "database_subnet_group" {
  description = "ID of database subnet group"
  value = element(concat(aws_db_subnet_group.database[*].id, tolist([
    ""
  ])), 0)
}

output "redshift_subnets" {
  description = "List of IDs of redshift subnets"
  value = zipmap(aws_subnet.redshift[*].tags["Name"], aws_subnet.redshift[*].id)
}

output "redshift_subnets_cidr_blocks" {
  description = "List of cidr_blocks of redshift subnets"
  value = zipmap(aws_subnet.redshift[*].tags["Name"], aws_subnet.redshift[*].cidr_block)
}

output "redshift_subnet_group" {
  description = "ID of redshift subnet group"
  value = element(concat(aws_redshift_subnet_group.redshift[*].id, tolist([
    ""
  ])), 0)
}

output "elasticache_subnets" {
  description = "List of IDs of elasticache subnets"
  value = zipmap(aws_subnet.elasticache[*].tags["Name"], aws_subnet.elasticache[*].id)
}

output "elasticache_subnets_cidr_blocks" {
  description = "List of cidr_blocks of elasticache subnets"
  value = zipmap(aws_subnet.elasticache[*].tags["Name"], aws_subnet.elasticache[*].cidr_block)
}

output "intra_subnets" {
  description = "List of IDs of intra subnets"
  value = zipmap(aws_subnet.intra[*].tags["Name"], aws_subnet.intra[*].id)
}

output "intra_subnets_cidr_blocks" {
  description = "List of cidr_blocks of intra subnets"
  value = zipmap(aws_subnet.intra[*].tags["Name"], aws_subnet.intra[*].cidr_block)
}

output "elasticache_subnet_group" {
  description = "ID of elasticache subnet group"
  value = element(concat(aws_elasticache_subnet_group.elasticache[*].id, tolist([
    ""
  ])), 0)
}

output "elasticache_subnet_group_name" {
  description = "Name of elasticache subnet group"
  value = element(concat(aws_elasticache_subnet_group.elasticache[*].name, tolist([
    ""
  ])), 0)
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = aws_route_table.public[*].id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables - including database route table IDs, as the database uses the private route tables"
  value       = aws_route_table.private[*].id
}

output "tgw_route_table_ids" {
  description = "List of IDs of tgw route tables"
  value       = aws_route_table.tgw[*].id
}

output "firewall_route_table_ids" {
  description = "List of IDs of firewall route tables"
  value       = aws_route_table.firewall[*].id
}

output "aws_nfw_endpoint_ids" {
  description = "List of IDs of AWS NFW endpoints"
  value       = module.aws_network_firewall[*].endpoint_id
}


output "redshift_route_table_ids" {
  description = "List of IDs of redshift route tables"
  value = [
    try(coalescelist(aws_route_table.redshift[*].id, aws_route_table.private[*].id), "")
  ]
}

output "elasticache_route_table_ids" {
  description = "List of IDs of elasticache route tables"
  value = [
    try(coalescelist(aws_route_table.elasticache[*].id, aws_route_table.private[*].id), "")
  ]
}

output "intra_route_table_ids" {
  description = "List of IDs of intra route tables"
  value       = aws_route_table.intra[*].id
}

output "nat_ids" {
  description = "List of allocation ID of Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat[*].id
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat[*].public_ip
}

output "natgw_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this[*].id
}

output "igw_id" {
  description = "The ID of the Internet Gateway"
  value       = element(concat(aws_internet_gateway.this[*].id, tolist([""])), 0)
}

output "vpc_endpoint_s3_id" {
  description = "The ID of VPC endpoint for S3"
  value       = element(concat(aws_vpc_endpoint.s3[*].id, tolist([""])), 0)
}

output "vpc_endpoint_s3_pl_id" {
  description = "The prefix list for the S3 VPC endpoint."
  value = element(concat(aws_vpc_endpoint.s3[*].prefix_list_id, tolist([
    ""
  ])), 0)
}

output "vpc_endpoint_dynamodb_id" {
  description = "The ID of VPC endpoint for DynamoDB"
  value       = element(concat(aws_vpc_endpoint.dynamodb[*].id, tolist([""])), 0)
}

output "vgw_id" {
  description = "The ID of the VPN Gateway"
  value = element(concat(aws_vpn_gateway.this[*].id, aws_vpn_gateway_attachment.this[*].vpn_gateway_id, tolist([
    ""
  ])), 0)
}

output "vpc_endpoint_dynamodb_pl_id" {
  description = "The prefix list for the DynamoDB VPC endpoint."
  value = element(concat(aws_vpc_endpoint.dynamodb[*].prefix_list_id, tolist([
    ""
  ])), 0)
}

output "default_vpc_id" {
  description = "The ID of the VPC"
  value       = element(concat(aws_default_vpc.this[*].id, tolist([""])), 0)
}

output "default_vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value = element(concat(aws_default_vpc.this[*].cidr_block, tolist([
    ""
  ])), 0)
}

output "default_vpc_default_security_group_id" {
  description = "The ID of the security group created by default on VPC creation"
  value = element(concat(aws_default_vpc.this[*].default_security_group_id, tolist([
    ""
  ])), 0)
}

output "default_vpc_default_network_acl_id" {
  description = "The ID of the default network ACL"
  value = element(concat(aws_default_vpc.this[*].default_network_acl_id, tolist([
    ""
  ])), 0)
}

output "default_vpc_default_route_table_id" {
  description = "The ID of the default route table"
  value = element(concat(aws_default_vpc.this[*].default_route_table_id, tolist([
    ""
  ])), 0)
}

output "default_vpc_instance_tenancy" {
  description = "Tenancy of instances spin up within VPC"
  value = element(concat(aws_default_vpc.this[*].instance_tenancy, tolist([
    ""
  ])), 0)
}

output "default_vpc_enable_dns_support" {
  description = "Whether or not the VPC has DNS support"
  value = element(concat(aws_default_vpc.this[*].enable_dns_support, tolist([
    ""
  ])), 0)
}

output "default_vpc_enable_dns_hostnames" {
  description = "Whether or not the VPC has DNS hostname support"
  value = element(concat(aws_default_vpc.this[*].enable_dns_hostnames, tolist([
    ""
  ])), 0)
}

output "default_vpc_main_route_table_id" {
  description = "The ID of the main route table associated with this VPC"
  value = element(concat(aws_default_vpc.this[*].main_route_table_id, tolist([
    ""
  ])), 0)
}
