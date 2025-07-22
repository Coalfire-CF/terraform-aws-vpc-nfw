aws_region              = "us-gov-west-1"
profile                 = "example-mgmt"
resource_prefix         = "example"
environment             = "prod" # app
account_number          = "0123456789" # app account number
app_vpc_cidr            = "172.16.0.0/16"
ip_network_app_prod     = "172.16"
cidrs_for_remote_access = ["0.0.0.0/32"]