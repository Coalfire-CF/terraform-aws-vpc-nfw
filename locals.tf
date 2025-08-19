locals {
  # from var.subnets, extract an object list of each type
  firewall_subnets    = [for s in var.subnets : s if s.type == "firewall"]
  public_subnets      = [for s in var.subnets : s if s.type == "public"]
  private_subnets     = [for s in var.subnets : s if s.type == "private"]
  tgw_subnets         = [for s in var.subnets : s if s.type == "tgw"]
  database_subnets    = [for s in var.subnets : s if s.type == "database"]
  redshift_subnets    = [for s in var.subnets : s if s.type == "redshift"]
  elasticache_subnets = [for s in var.subnets : s if s.type == "elasticache"]
  intra_subnets       = [for s in var.subnets : s if s.type == "intra"]
}
