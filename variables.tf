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

variable "nfw_kms_key_arn" {
  description = "ARN of the KMS key to use for NFW encryption"
  type        = string
  default     = null
}

################
# TLS Inspection
################

variable "enable_tls_inspection" {
  description = "enable nfw tls inspection true/false. deploy_aws_nfw must be true to enable this"
  type        = bool
  default     = false
}

variable "tls_cert_arn" {
  description = "TLS Certificate ARN"
  type        = string
  default     = ""
}

variable "tls_description" {
  description = "Description for the TLS Inspection"
  type        = string
  default     = "TLS Oubound Inspection"
}

variable "tls_destination_cidrs" {
  description = "Destination CIDRs for TLS Inspection"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tls_destination_from_port" {
  description = "Destination Port for TLS Inspection"
  type        = number
  default     = 443
}

variable "tls_destination_to_port" {
  description = "Destination Port for TLS Inspection"
  type        = number
  default     = 443
}

variable "tls_source_cidr" {
  description = "Source CIDR for TLS Inspection"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tls_source_from_port" {
  description = "Source Port for TLS Inspection"
  type        = number
  default     = 0
}

variable "tls_source_to_port" {
  description = "Source Port for TLS Inspection"
  type        = number
  default     = 65535
}

######
# VPC
######
variable "resource_prefix" {
  description = "Prefix to be added to resource names as identifier"
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

variable "private_eks_tags" {
  description = "A map of tags to add to all privage subnets resources to support EKS"
  default     = {}
  type        = map(string)
}

variable "public_eks_tags" {
  description = "A map of tags to add to all public subnets resources to support EKS"
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

variable "firewall_subnet_name_tag" {
  description = "Additional name tag for the firewall subnets"
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

variable "tgw_route_table_tags" {
  description = "Additional tags for the tgw route tables"
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

variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain Cloudwatch logs"
  type        = number
  default     = 365
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "Customer KMS Key id for Cloudwatch Log encryption"
  type        = string
  default     = ""
}

variable "s3_access_logs_bucket" {
  description = "bucket id for s3 access logs bucket"
  type        = string
  default     = ""
}


variable "s3_kms_key_arn" {
  description = "Customer KMS Key id for Cloudwatch Log encryption"
  type        = string
  default     = ""
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
    vpc_peering_connection_id  = optional(string, null)
    vpc_endpoint_id            = optional(string, null)
  }))
  default = []
}



variable "tgw_custom_routes" {
  description = "Custom routes for TGW Subnets"
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

variable "create_vpc_endpoints" {
  description = "Whether to create VPC endpoints"
  type        = bool
  default     = false
}

variable "associate_with_private_route_tables" {
  description = "Whether to associate Gateway endpoints with private route tables"
  type        = bool
  default     = true
}

variable "associate_with_public_route_tables" {
  description = "Whether to associate Gateway endpoints with public route tables"
  type        = bool
  default     = false
}

variable "vpc_endpoints" {
  description = "Map of VPC endpoint definitions to create"
  type = map(object({
    service_name        = optional(string)     # If not provided, standard AWS service name will be constructed
    service_type        = string               # "Interface", "Gateway", or "GatewayLoadBalancer"
    private_dns_enabled = optional(bool, true) # Only applicable for Interface endpoints
    auto_accept         = optional(bool, false)
    policy              = optional(string) # JSON policy document
    security_group_ids  = optional(list(string), [])
    tags                = optional(map(string), {})
    subnet_ids          = optional(list(string)) # Override default subnet_ids if needed
    # Required only for GatewayLoadBalancer endpoints
    ip_address_type = optional(string) # "ipv4" or "dualstack"
  }))
  default = {}
}

variable "vpc_endpoint_security_groups" {
  description = "Map of security groups to create for VPC endpoints"
  type = map(object({
    name        = string
    description = optional(string, "Security group for VPC endpoint")
    ingress_rules = optional(list(object({
      description      = optional(string)
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
      security_groups  = optional(list(string), [])
      self             = optional(bool, false)
    })), [])
    egress_rules = optional(list(object({
      description      = optional(string)
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
      security_groups  = optional(list(string), [])
      self             = optional(bool, false)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

variable "subnet_az_mapping" {
  description = "Optional explicit mapping of subnets to AZs - defaults to distributing across AZs"
  type        = map(string)
  default     = {}
}

variable "subnets" {
  type = list(object({
    custom_name       = optional(string)
    tag               = optional(string)
    cidr              = string
    type              = string
    availability_zone = string
  }))

  ### There are MANY invalid configurations for this input object which terraform will not catch, but the AWS API will reject during apply
  ### We must define input validation rules for each known error:

  # Error if subnet type is not an allowed value
  validation {
    condition = length([
      for subnet in var.subnets[*].type : true if contains([
        "firewall",
        "public",
        "private",
        "tgw",
        "database",
        "redshift",
        "elasticache",
        "intra"
        ],
      subnet)
    ]) == length(var.subnets)
    error_message = "Allowed subnet types are 'firewall', 'public', 'private', 'tgw', 'database', 'redshift', 'elasticache', and 'intra'."
  }
  # Error if the number of public subnets is less than the number of firewall subnets
  validation {
    condition     = length([for s in var.subnets : s if s.type == "public"]) >= length([for s in var.subnets : s if s.type == "firewall"])
    error_message = "The number of public subnets must be greater than or equal to the number of firewall subnets to accomodate IGW routing from the NFW."
  }
  # Error if multiple subnets are defined with the same CIDR
  validation {
    condition     = length(var.subnets) == length(distinct([for s in var.subnets : s.cidr]))
    error_message = "Each subnet must have a unique CIDR."
  }
  # Error if BOTH 'tag' and 'custom_name' are defined for any subnet
  validation {
    condition     = length([for s in var.subnets : s if s.custom_name != null && s.tag != null]) == 0
    error_message = "Subnets must have only one of 'custom_name' or 'tag' defined. (i.e. you cannot specify both a 'custom_name' and a 'tag' for the same subnet)."
  }
  # Error if NEITHER 'tag' nor 'custom_name' are defined for any subnet
  validation {
    condition     = length([for s in var.subnets : s if s.custom_name == null && s.tag == null]) == 0
    error_message = "You must provide one of either 'custom_name' or 'tag' for each subnet."
  }
}

variable "database_subnet_group_name" {
  description = "Optional custom resource name for the database subnet group"
  type        = string
  default     = null
}

variable "redshift_subnet_group_name" {
  description = "Optional custom resource name for the Redshift subnet group"
  type        = string
  default     = null
}

variable "elasticache_subnet_group_name" {
  description = "Optional custom resource name for the Elasticache subnet group"
  type        = string
  default     = null
}
