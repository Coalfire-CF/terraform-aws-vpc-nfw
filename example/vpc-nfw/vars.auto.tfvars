profile                 = "ooc-mgmt"
mgmt_vpc_cidr           = "10.0.0.0/16"
aws_region              = "us-gov-west-1"
deploy_aws_nfw          = true
resource_prefix         = "mvp"
cidrs_for_remote_access = ["172.16.0.0/24"]
enable_tls_inspection = false # Enable TLS Inspection. deploy_aws_nfw must be true to enable this feature
tls_cert_arn          = ""
tls_destination_cidrs = []
