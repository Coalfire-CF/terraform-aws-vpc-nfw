provider "aws" {
  region            = var.aws_region
  profile           = var.profile
  alias             = "mgmt"
  use_fips_endpoint = true
  ignore_tags {
    keys = ["map-migrated"]
  }
}