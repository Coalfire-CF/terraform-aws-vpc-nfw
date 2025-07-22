profile         = "example-mgmt"
mgmt_vpc_cidr   = "10.1.0.0/16"
aws_region      = "us-gov-west-1"
resource_prefix = "example"

#NFW
deploy_aws_nfw          = true
delete_protection       = true
cidrs_for_remote_access = [""] #List of CIDRS for remote acess (example, CF VPN).

#enable_tls_inspection = false # Enable TLS Inspection. deploy_aws_nfw must be true to enable this feature
#tls_cert_arn          = ""
#tls_destination_cidrs = []