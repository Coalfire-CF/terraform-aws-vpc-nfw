variable "create_vpc_endpoints" {
  description = "Whether to create VPC endpoints. If set to false, no VPC endpoints will be created regardless of endpoints map."
  type        = bool
  default     = false
}

variable "enable_fips_endpoints" {
  description = "Whether to use FIPS endpoints where available. Typically used for GovCloud and other regulated environments."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "ID of the VPC where endpoints will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where interface endpoints will be created"
  type        = list(string)
  default     = []
}

variable "route_table_ids" {
  description = "List of route table IDs to associate with gateway endpoints"
  type        = list(string)
  default     = []
}

variable "vpc_endpoints" {
  description = "Map of VPC endpoint definitions to create"
  type = map(object({
    service_name        = optional(string)       # If not provided, standard AWS service name will be constructed
    service_type        = string                 # "Interface", "Gateway", or "GatewayLoadBalancer"
    private_dns_enabled = optional(bool, true)   # Only applicable for Interface endpoints
    auto_accept         = optional(bool, false)
    policy              = optional(string)       # JSON policy document
    security_group_ids  = optional(list(string), [])
    tags                = optional(map(string), {})
    subnet_ids          = optional(list(string)) # Override default subnet_ids if needed
    # Required only for GatewayLoadBalancer endpoints
    ip_address_type     = optional(string)       # "ipv4" or "dualstack"
  }))
  default = {}
}

variable "security_groups" {
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

variable "tags" {
  description = "Map of common tags to apply to all resources"
  type        = map(string)
  default     = {}
}