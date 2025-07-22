terraform {
  backend "s3" {
    bucket       = "example-us-gov-west-1-tf-state"
    region       = "us-gov-west-1"
    key          = "example-us-gov-west-1-networking.tfstate"
    encrypt      = true
    use_lockfile = true
  }
}

data "terraform_remote_state" "account-setup" {
  backend   = "s3"
  workspace = "default"
  config = {
    bucket  = "${var.resource_prefix}-us-gov-west-1-tf-state"
    region  = var.aws_region
    key     = "${var.resource_prefix}-us-gov-west-1-account-setup.tfstate"
    profile = var.profile
  }
}

data "aws_partition" "current" {
}

data "aws_caller_identity" "current" {
}

data "aws_availability_zones" "available" {
  state = "available"
}