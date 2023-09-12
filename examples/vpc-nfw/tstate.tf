terraform {
  required_version = "~>1.0"
  backend "s3" {
    # See ./backends/<environment> for backend details
  }
}