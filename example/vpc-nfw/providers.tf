provider "aws" {
  region            = var.aws_region
  profile           = var.profile
  use_fips_endpoint = true
  default_tags {
    tags = {
      "FedRAMP"   = "True"
      "Terraform" = "True"
    }
  }
}