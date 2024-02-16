locals {
  account_id       = data.aws_caller_identity.current.account_id
  partition        = data.aws_partition.current.partition
  firewall_subnets = [for k, v in module.mgmt_subnet_addrs.network_cidr_blocks : v if length(regexall(".*firewall.*", k)) > 0]
  public_subnets   = [for k, v in module.mgmt_subnet_addrs.network_cidr_blocks : v if length(regexall(".*public.*", k)) > 0]
  private_subnets  = [for k, v in module.mgmt_subnet_addrs.network_cidr_blocks : v if(length(regexall(".*priv.*", k)) > 0 || length(regexall(".*compute.*", k)) > 0)]
  tgw_subnets = [for k, v in module.mgmt_subnet_addrs.network_cidr_blocks : v if length(regexall(".*tgw.*", k)) > 0]
  workspaces_subnets = [for k, v in module.mgmt_subnet_addrs.network_cidr_blocks : v if length(regexall(".*workspaces.*", k)) > 0]
  workspace_azs = lookup(var.workspaces_azs, var.aws_region, "")
}