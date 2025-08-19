variable "profile" {
  description = "The AWS profile aligned with the AWS environment to deploy to"
  type        = string
}

variable "resource_prefix" {
  description = "A prefix that should be attached to the names of resources"
  type        = string
}

variable "environment" {
  description = "The environment where resources will be deployed (mgmt, app, etc.)"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
}

variable "app_vpc_cidr" {
  description = "The CIDR range of the VPC"
  type        = string
}
variable "cidrs_for_remote_access" {
  description = "List of IPv4 CIDR ranges to access all admins remote access"
  type        = list(string)
}

variable "ip_network_app_prod" {
  description = "Network part of Security operations CIDR"
  type        = string
}

variable "account_number" {
  description = "AWS Account Number"
  type        = string
}

#variable "delete_protection" {
#  description = "Whether or not to enable deletion protection of NFW"
#  type        = bool
#  default     = true
#}
#
#variable "deploy_aws_nfw" {
#  description = "enable nfw true/false"
#  type        = bool
#  default     = false
#}
#
#variable "create_vpc_endpoints" {
#  description = "enable vpc endpoints true/false"
#  type        = bool
#  default     = false
#}
#
#variable "is_gov" {
#  description = "Whether or not the environment is being deployed in GovCloud"
#  type        = bool
#  default     = true
#}
#