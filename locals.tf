locals {
  firewall_subnets              = tolist([for s in var.subnets : s if s.type == "firewall"])
  public_subnets                = tolist([for s in var.subnets : s if s.type == "public"])
  private_subnets               = tolist([for s in var.subnets : s if s.type == "private"])
  tgw_subnets                   = tolist([for s in var.subnets : s if s.type == "tgw"])
  database_subnets              = tolist([for s in var.subnets : s if s.type == "database"])
  redshift_subnets              = tolist([for s in var.subnets : s if s.type == "redshift"])
  elasticache_subnets           = tolist([for s in var.subnets : s if s.type == "elasticache"])
  intra_subnets                 = tolist([for s in var.subnets : s if s.type == "firewall"])
  database_subnet_group_name    = "todo"
  redshift_subnet_group_name    = "todo"
  elasticache_subnet_group_name = "todo"
}
