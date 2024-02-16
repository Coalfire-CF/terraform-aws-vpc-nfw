variable "profile" {
  description = "The AWS profile aligned with the AWS environment to deploy to"
  type        = string
}

variable "resource_prefix" {
  description = "A prefix that should be attached to the names of resources"
  type        = string
}

variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
}

variable "mgmt_vpc_cidr" {
  description = "The CIDR range of the VPC"
  type        = string
}
variable "cidrs_for_remote_access" {
  description = "List of IPv4 CIDR ranges to access all admins remote access"
  type        = list(string)
}
variable "delete_protection" {
  description = "Whether or not to enable deletion protection of NFW"
  type        = bool
  default     = true
}

variable "deploy_aws_nfw" {
  description = "enable nfw true/false"
  type        = bool
  default     = false
}


##if using AWS workspaces https://docs.aws.amazon.com/workspaces/latest/adminguide/azs-workspaces.html
## us-east-1 = us-east-1b, us-east-1c, us-east-1d
## us-west-2 = us-west-2a, us-west-2b, us-west-2c
## us-gov-west-1 = us-gov-west-1a, us-gov-west-1b, us-gov-west-1c
## us-gov-east-1 = us-gov-east-1a, us-gov-east-1b, us-gov-east-1
variable "workspaces_azs" {
  description = "AZ list for matching of region to AZ, no spaces in the values due to how its being parsed and split"
  type = map(string)
  default = {
    "us-east-1" = "us-east-1b,us-east-1c,us-east-1d"
    "us-west-2" = "us-west-2a,us-west-2b,us-west-2c"
    "us-gov-west-1" = "us-gov-west-1a,us-gov-west-1b,us-gov-west-1c"
    "us-gov-east-1" = "us-gov-east-1a,us-gov-east-1b,us-gov-east-1"
  }
}
