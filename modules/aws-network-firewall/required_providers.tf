terraform {
  required_version = "~>1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.97.0, < 6.0"
    }
  }
}