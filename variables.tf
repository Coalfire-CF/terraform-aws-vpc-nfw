###################
# Network Firewall
###################

variable "deploy_aws_nfw" {
  description = "enable nfw true/false"
  type        = bool
  default     = false
}

variable "aws_nfw_prefix" {
  description = "AWS NFW Prefix"
  type        = string
  default     = ""
}

variable "aws_nfw_name" {
  description = "AWS NFW Name"
  type        = string
  default     = ""
}

variable "aws_nfw_stateless_rule_group" {
  description = "AWS NFW sateless rule group"
  type = list(object({
    name        = string
    description = string
    capacity    = number
    rule_config = list(object({
      protocols_number      = list(number)
      source_ipaddress      = string
      source_to_port        = string
      destination_to_port   = string
      destination_ipaddress = string
      tcp_flag = object({
        flags = list(string)
        masks = list(string)
      })
      actions = map(string)
    }))
  }))
  default = []
}

variable "aws_nfw_fivetuple_stateful_rule_group" {
  description = "Config for 5-tuple type stateful rule group"
  type = list(object({
    name        = string
    description = string
    capacity    = number
    rule_config = list(object({
      description           = string
      protocol              = string
      source_ipaddress      = string
      source_port           = string
      direction             = string
      destination_port      = string
      destination_ipaddress = string
      sid                   = number
      actions               = map(string)
    }))
  }))
  default = []
}

variable "aws_nfw_domain_stateful_rule_group" {
  description = "Config for domain type stateful rule group"
  type = list(object({
    name        = string
    description = string
    capacity    = number
    domain_list = list(string)
    actions     = string
    protocols   = list(string)
    rules_file  = optional(string, "")
    rule_variables = optional(object({
      ip_sets = list(object({
        key    = string
        ip_set = list(string)
      }))
      port_sets = list(object({
        key       = string
        port_sets = list(string)
      }))
      }), {
      ip_sets   = []
      port_sets = []
    })
  }))
  default = []
}

variable "aws_nfw_suricata_stateful_rule_group" {
  description = "Config for Suricata type stateful rule group"
  type = list(object({
    name        = string
    description = string
    capacity    = number
    rules_file  = optional(string, "")
    rule_variables = optional(object({
      ip_sets = list(object({
        key    = string
        ip_set = list(string)
      }))
      port_sets = list(object({
        key       = string
        port_sets = list(string)
      }))
      }), {
      ip_sets   = []
      port_sets = []
    })
  }))
  default = []
}

variable "delete_protection" {
  description = "Whether or not to enable deletion protection of NFW"
  type        = bool
  default     = true
}

variable "nfw_kms_key_id" {
  description = "NFW KMS Key Id for encryption"
  type        = string
  default     = null
}

######
# VPC
######
variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = ""
  type        = string
}

variable "cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "assign_generated_ipv6_cidr_block" {
  description = "Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC. You cannot specify the range of IP addresses, or the size of the CIDR block"
  default     = false
  type        = bool
}

variable "secondary_cidr_blocks" {
  description = "List of secondary CIDR blocks to associate with the VPC to extend the IP Address pool"
  default     = []
  type        = list(string)
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  default     = "default"
  type        = string
}

variable "public_subnet_suffix" {
  description = "Suffix to append to public subnets name"
  default     = "public"
  type        = string
}

variable "private_subnet_suffix" {
  description = "Suffix to append to private subnets name"
  default     = "private"
  type        = string
}

variable "firewall_subnet_suffix" {
  description = "Suffix to append to firewall subnets name"
  default     = "firewall"
  type        = string
}

variable "database_subnet_suffix" {
  description = "Suffix to append to database subnets name"
  default     = "db"
  type        = string
}

variable "redshift_subnet_suffix" {
  description = "Suffix to append to redshift subnets name"
  default     = "redshift"
  type        = string
}

variable "elasticache_subnet_suffix" {
  description = "Suffix to append to elasticache subnets name"
  default     = "elasticache"
  type        = string
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC"
  default     = []
  type        = list(string)
}

variable "firewall_subnets" {
  description = "A list of firewall subnets inside the VPC"
  default     = []
  type        = list(string)
}

variable "private_subnets" {
  description = "A list of private subnets inside the VPC"
  default     = {}
  type        = map(string)
}

variable "database_subnets" {
  type        = list(string)
  description = "A list of database subnets"
  default     = []
}

variable "redshift_subnets" {
  type        = list(string)
  description = "A list of redshift subnets"
  default     = []
}

variable "elasticache_subnets" {
  type        = list(string)
  description = "A list of elasticache subnets"
  default     = []
}

variable "create_database_subnet_route_table" {
  description = "Controls if separate route table for database should be created"
  default     = false
  type        = bool
}

variable "create_redshift_subnet_route_table" {
  description = "Controls if separate route table for redshift should be created"
  default     = false
  type        = bool
}

variable "create_elasticache_subnet_route_table" {
  description = "Controls if separate route table for elasticache should be created"
  default     = false
  type        = bool
}

variable "intra_subnets" {
  type        = list(string)
  description = "A list of intra subnets"
  default     = []
}

variable "create_database_subnet_group" {
  description = "Controls if database subnet group should be created"
  default     = true
  type        = bool
}

variable "azs" {
  description = "A list of availability zones in the region"
  default     = []
  type        = list(string)
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  default     = false
  type        = bool
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  default     = true
  type        = bool
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  default     = false
  type        = bool
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  default     = false
  type        = bool
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs`."
  default     = false
  type        = bool
}

variable "reuse_nat_ips" {
  description = "Should be true if you don't want EIPs to be created for your NAT Gateways and will instead pass them in via the 'external_nat_ip_ids' variable"
  default     = false
  type        = bool
}

variable "external_nat_ip_ids" {
  description = "List of EIP IDs to be assigned to the NAT Gateways (used in combination with reuse_nat_ips)"
  type        = list(string)
  default     = []
}

variable "enable_dynamodb_endpoint" {
  description = "Should be true if you want to provision a DynamoDB endpoint to the VPC"
  default     = false
  type        = bool
}

variable "enable_s3_endpoint" {
  description = "Should be true if you want to provision an S3 endpoint to the VPC"
  default     = false
  type        = bool
}

variable "map_public_ip_on_launch" {
  description = "Should be false if you do not want to auto-assign public IP on launch"
  default     = true
  type        = bool
}

variable "enable_vpn_gateway" {
  description = "Should be true if you want to create a new VPN Gateway resource and attach it to the VPC"
  default     = false
  type        = bool
}

variable "flow_log_destination_arn" {
  description = "The ARN of the Cloudwatch log destination for Flow Logs"
  type        = string
  default     = null
}

variable "flow_log_destination_type" {
  description = "Type of flow log destination. Can be s3 or cloud-watch-logs"
  type        = string
  validation {
    condition     = can(regex("^(cloud-watch-logs|s3)$", var.flow_log_destination_type))
    error_message = "ERROR: benchmark value must match 'cloud-watch-logs' or 's3'."
  }
}

variable "vpn_gateway_id" {
  description = "ID of VPN Gateway to attach to the VPC"
  default     = ""
  type        = string
}

variable "propagate_private_route_tables_vgw" {
  description = "Should be true if you want route table propagation"
  default     = false
  type        = bool
}

variable "propagate_public_route_tables_vgw" {
  description = "Should be true if you want route table propagation"
  default     = false
  type        = bool
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = {}
  type        = map(string)
}

variable "vpc_tags" {
  description = "Additional tags for the VPC"
  default     = {}
  type        = map(string)
}

variable "igw_tags" {
  description = "Additional tags for the internet gateway"
  default     = {}
  type        = map(string)
}

variable "public_subnet_tags" {
  description = "Additional tags for the public subnets"
  default     = {}
  type        = map(string)
}

variable "firewall_subnet_name_tag" {
  description = "Additional name tag for the firewall subnets"
  default     = {}
  type        = map(string)
}

variable "private_subnet_tags" {
  description = "Additional tags for the private subnets"
  default     = {}
  type        = map(string)
}

variable "private_subnet_name_tag" {
  description = "Additional name tag for the private subnets"
  default     = {}
  type        = map(string)
}

variable "intra_subnet_name_tag" {
  description = "Additional name tag for the intranet subnets"
  default     = {}
  type        = map(string)
}

variable "public_route_table_tags" {
  description = "Additional tags for the public route tables"
  default     = {}
  type        = map(string)
}

variable "firewall_route_table_tags" {
  description = "Additional tags for the firewall route tables"
  default     = {}
  type        = map(string)
}


variable "private_route_table_tags" {
  description = "Additional tags for the private route tables"
  default     = {}
  type        = map(string)
}

variable "database_route_table_tags" {
  description = "Additional tags for the database route tables"
  default     = {}
  type        = map(string)
}

variable "redshift_route_table_tags" {
  description = "Additional tags for the redshift route tables"
  default     = {}
  type        = map(string)
}

variable "elasticache_route_table_tags" {
  description = "Additional tags for the elasticache route tables"
  default     = {}
  type        = map(string)
}

variable "intra_route_table_tags" {
  description = "Additional tags for the intra route tables"
  default     = {}
  type        = map(string)
}

variable "database_subnet_tags" {
  description = "Additional tags for the database subnets"
  default     = {}
  type        = map(string)
}

variable "database_subnet_group_tags" {
  description = "Additional tags for the database subnet group"
  default     = {}
  type        = map(string)
}

variable "redshift_subnet_tags" {
  description = "Additional tags for the redshift subnets"
  default     = {}
  type        = map(string)
}

variable "redshift_subnet_group_tags" {
  description = "Additional tags for the redshift subnet group"
  default     = {}
  type        = map(string)
}

variable "elasticache_subnet_tags" {
  description = "Additional tags for the elasticache subnets"
  default     = {}
  type        = map(string)
}

variable "intra_subnet_tags" {
  description = "Additional tags for the intra subnets"
  default     = {}
  type        = map(string)
}

variable "dhcp_options_tags" {
  description = "Additional tags for the DHCP option set"
  default     = {}
  type        = map(string)
}

variable "nat_gateway_tags" {
  description = "Additional tags for the NAT gateways"
  default     = {}
  type        = map(string)
}

variable "nat_eip_tags" {
  description = "Additional tags for the NAT EIP"
  default     = {}
  type        = map(string)
}

variable "vpn_gateway_tags" {
  description = "Additional tags for the VPN gateway"
  default     = {}
  type        = map(string)
}

variable "enable_dhcp_options" {
  description = "Should be true if you want to specify a DHCP options set with a custom domain name, DNS servers, NTP servers, netbios servers, and/or netbios server type"
  default     = false
  type        = bool
}

variable "dhcp_options_domain_name" {
  description = "Specifies DNS name for DHCP options set"
  default     = ""
  type        = string
}

variable "dhcp_options_domain_name_servers" {
  description = "Specify a list of DNS server addresses for DHCP options set, default to AWS provided"
  type        = list(string)
  default     = ["AmazonProvidedDNS"]
}

variable "dhcp_options_ntp_servers" {
  description = "Specify a list of NTP servers for DHCP options set"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_name_servers" {
  description = "Specify a list of netbios servers for DHCP options set"
  type        = list(string)
  default     = []
}

variable "dhcp_options_netbios_node_type" {
  description = "Specify netbios node_type for DHCP options set"
  default     = ""
  type        = string
}

variable "manage_default_vpc" {
  description = "Should be true to adopt and manage Default VPC"
  default     = false
  type        = bool
}

variable "default_vpc_name" {
  description = "Name to be used on the Default VPC"
  default     = ""
  type        = string
}

variable "default_vpc_enable_dns_support" {
  description = "Should be true to enable DNS support in the Default VPC"
  default     = true
  type        = bool
}

variable "default_vpc_enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the Default VPC"
  default     = false
  type        = bool
}

variable "default_vpc_tags" {
  description = "Additional tags for the Default VPC"
  default     = {}
  type        = map(string)
}
variable "dynamodb_endpoint_type" {
  description = "DynamoDB VPC endpoint type"
  type        = string
  default     = "Gateway"
}
variable "s3_endpoint_type" {
  description = "S3 VPC endpoint type"
  type        = string
  default     = "Gateway"
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain Cloudwatch logs"
  type        = number
  default     = 365
}
variable "cloudwatch_log_group_kms_key_id" {
  description = "Customer KMS Key id for Cloudwatch Log encryption"
  type        = string
}

variable "database_custom_routes" {
  description = "Custom routes for Database Subnets"
  type = list(object({
    destination_cidr_block     = optional(string, null)
    destination_prefix_list_id = optional(string, null)
    network_interface_id       = optional(string, null)
    transit_gateway_id         = optional(string, null)
    vpc_endpoint_id            = optional(string, null)
  }))
  default = []
}

variable "elasticache_custom_routes" {
  description = "Custom routes for Elasticache Subnets"
  type = list(object({
    destination_cidr_block     = optional(string, null)
    destination_prefix_list_id = optional(string, null)
    network_interface_id       = optional(string, null)
    transit_gateway_id         = optional(string, null)
    vpc_endpoint_id            = optional(string, null)
  }))
  default = []
}

variable "firewall_custom_routes" {
  description = "Custom routes for Firewall Subnets"
  type        = list(map(string))
  default     = []
}

variable "intra_custom_routes" {
  description = "Custom routes for Intra Subnets"
  type = list(object({
    destination_cidr_block     = optional(string, null)
    destination_prefix_list_id = optional(string, null)
    network_interface_id       = optional(string, null)
    transit_gateway_id         = optional(string, null)
    vpc_endpoint_id            = optional(string, null)
  }))
  default = []
}

variable "private_custom_routes" {
  description = "Custom routes for Private Subnets"
  type = list(object({
    destination_cidr_block     = optional(string, null)
    destination_prefix_list_id = optional(string, null)
    network_interface_id       = optional(string, null)
    transit_gateway_id         = optional(string, null)
    vpc_endpoint_id            = optional(string, null)
  }))
  default = []
}

variable "public_custom_routes" {
  description = "Custom routes for Public Subnets"
  type = list(object({
    destination_cidr_block     = optional(string, null)
    destination_prefix_list_id = optional(string, null)
    network_interface_id       = optional(string, null)
    internet_route             = optional(bool, null)
    transit_gateway_id         = optional(string, null)
  }))
  default = []
}

variable "redshift_custom_routes" {
  description = "Custom routes for Redshift Subnets"
  type = list(object({
    destination_cidr_block     = optional(string, null)
    destination_prefix_list_id = optional(string, null)
    network_interface_id       = optional(string, null)
    transit_gateway_id         = optional(string, null)
    vpc_endpoint_id            = optional(string, null)
  }))
  default = []
}
