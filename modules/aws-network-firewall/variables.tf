### NFW ###
variable "prefix" {
  description = "The description for each environment, ie: bin-dev"
  type        = string
}

variable "tags" {
  description = "The tags for the resources"
  type        = map(any)
  default     = {}
}

variable "description" {
  description = "Description for the resources"
  default     = ""
  type        = string
}

variable "fivetuple_stateful_rule_group" {
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

variable "domain_stateful_rule_group" {
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

variable "suricata_stateful_rule_group" {
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
  default = [{
    name        = "DefaultSuricataDenyAll"
    description = "Default Deny All Rules for NFW"
    capacity    = 1000
    rules_file  = "./nfw-base-suricata-rules.json"
    rule_variables = {
      ip_sets   = []
      port_sets = []
    }
  }]
}

variable "stateless_rule_group" {
  description = "Config for stateless rule group"
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

variable "firewall_name" {
  description = "firewall name"
  type        = string
  default     = "example"
}

variable "subnet_mapping" {
  description = "Subnet ids mapping to have individual firewall endpoint"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "stateless_default_actions" {
  description = "Default stateless Action"
  type        = string
  default     = "forward_to_sfe"
}

variable "stateless_fragment_default_actions" {
  description = "Default Stateless action for fragmented packets"
  type        = string
  default     = "forward_to_sfe"
}

variable "firewall_policy_change_protection" {
  type        = string
  description = "(Option) A boolean flag indicating whether it is possible to change the associated firewall policy"
  default     = false
}

variable "subnet_change_protection" {
  type        = string
  description = "(Optional) A boolean flag indicating whether it is possible to change the associated subnet(s)"
  default     = false
}

variable "stateful_managed_rule_groups_arns" {
  description = "https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy#action"
  type        = list(string)
  default     = []
}

variable "nfw_kms_key_id" {
  description = "NFW KMS Key Id for encryption"
  type        = string
}

variable "delete_protection" {
  description = "Whether or not to enable deletion protection of NFW"
  type        = bool
  default     = true
}

### Logging ###
variable "cloudwatch_log_group_retention_in_days" {
  description = "Number of days to retain Cloudwatch logs"
  type        = number
  default     = 365
}
variable "cloudwatch_log_group_kms_key_id" {
  description = "Customer KMS Key id for Cloudwatch Log encryption"
  type        = string
}

### TLS Outbound Inspection ###

variable "tls_inspection_enabled" {
  description = "Enable TLS Inspection"
  type        = bool
  default     = false
}

variable "tls_description" {
  description = "Description for the TLS Inspection"
  type        = string
  default     = "TLS Oubound Inspection"
}

variable "tls_cert_arn" {
  description = "TLS Certificate ARN"
  type        = string
  default     = ""
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

variable "stateful_default_actions" {
  description = "Set of actions to take on a packet if it does not match any stateful rules in the policy. This can only be specified if the policy has a `stateful_engine_options` block with a rule_order value of `STRICT_ORDER`. You can specify one of either or neither values of `aws:drop_strict` or `aws:drop_established`, as well as any combination of `aws:alert_strict` and `aws:alert_established`"
  type        = list(string)
  default     = []
}

variable "stateful_engine_options" {
  description = "A configuration block that defines options on how the policy handles stateful rules. See [Stateful Engine Options](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy#stateful-engine-options) for details"
  type        = any
  default     = {}
}
