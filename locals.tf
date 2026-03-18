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

  # Per-cluster kubernetes.io/cluster/<name> tags
  eks_cluster_tags = { for name in var.eks_cluster_names : "kubernetes.io/cluster/${name}" => var.eks_cluster_tag_value }

  # EKS tags for private subnets (internal-elb + karpenter discovery)
  eks_private_subnet_tags = var.enable_eks_subnet_tagging ? merge(
    local.eks_cluster_tags,
    var.enable_eks_private_subnet_tags ? { "kubernetes.io/role/internal-elb" = "1" } : {},
    var.enable_karpenter_subnet_tags ? {
      "karpenter.sh/discovery" = var.karpenter_discovery_tag_value != "" ? var.karpenter_discovery_tag_value : try(var.eks_cluster_names[0], "")
    } : {}
  ) : {}

  # EKS tags for public subnets (external elb)
  eks_public_subnet_tags = var.enable_eks_subnet_tagging ? merge(
    local.eks_cluster_tags,
    var.enable_eks_public_subnet_tags ? { "kubernetes.io/role/elb" = "1" } : {}
  ) : {}
}
