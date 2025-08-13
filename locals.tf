locals {
  firewall_subnets              = [for s in var.subnets : s if s.type == "firewall"]
  public_subnets                = [for s in var.subnets : s if s.type == "public"]
  private_subnets               = [for s in var.subnets : s if s.type == "private"]
  tgw_subnets                   = [for s in var.subnets : s if s.type == "tgw"]
  database_subnets              = [for s in var.subnets : s if s.type == "database"]
  redshift_subnets              = [for s in var.subnets : s if s.type == "redshift"]
  elasticache_subnets           = [for s in var.subnets : s if s.type == "elasticache"]
  intra_subnets                 = [for s in var.subnets : s if s.type == "firewall"]
  database_subnet_group_name    = "todo"
  redshift_subnet_group_name    = "todo"
  elasticache_subnet_group_name = "todo"
}
