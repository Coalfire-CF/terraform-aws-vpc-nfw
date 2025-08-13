locals {
  firewall_subnets              = tomap([for s in var.subnets : s if s.type == "firewall"])
  public_subnets                = tomap([for s in var.subnets : s if s.type == "public"])
  private_subnets               = tomap([for s in var.subnets : s if s.type == "private"])
  tgw_subnets                   = tomap([for s in var.subnets : s if s.type == "tgw"])
  database_subnets              = tomap([for s in var.subnets : s if s.type == "database"])
  redshift_subnets              = tomap([for s in var.subnets : s if s.type == "redshift"])
  elasticache_subnets           = tomap([for s in var.subnets : s if s.type == "elasticache"])
  intra_subnets                 = tomap([for s in var.subnets : s if s.type == "firewall"])
  database_subnet_group_name    = "todo"
  redshift_subnet_group_name    = "todo"
  elasticache_subnet_group_name = "todo"
}
