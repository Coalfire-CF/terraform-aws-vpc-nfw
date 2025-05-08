output "vpc_endpoint_ids" {
  description = "Map of VPC endpoint IDs"
  value       = { for k, v in aws_vpc_endpoint.this : k => v.id }
}

output "vpc_endpoint_dns_entries" {
  description = "DNS entries for VPC endpoints"
  value       = { for k, v in aws_vpc_endpoint.this : k => v.dns_entry }
}

output "security_groups" {
  description = "Map of security group IDs created for VPC endpoints"
  value       = { for k, v in aws_security_group.endpoint_sg : k => v.id }
}