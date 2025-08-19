provider "aws" {
  region                 = var.aws_region
  profile                = var.profile
  alias                  = "example-app"
  skip_region_validation = true
  use_fips_endpoint      = true
  assume_role {
    role_arn = "arn:${local.partition}:iam::${local.prod_app_account_id}:role/OrganizationAccountAccessRole"
  }
}