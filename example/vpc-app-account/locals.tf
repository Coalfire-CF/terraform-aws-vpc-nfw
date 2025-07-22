locals {
  partition  = data.aws_partition.current.partition
  prod_app_account_id = var.account_number
  firewall_subnets = [
    "${var.ip_network_app_prod}.1.0/24",
    "${var.ip_network_app_prod}.2.0/24"
  ]
  public_subnets = [
    "${var.ip_network_app_prod}.3.0/24",
    "${var.ip_network_app_prod}.4.0/24"
  ]
  private_subnets = [
    "${var.ip_network_app_prod}.5.0/24",
    "${var.ip_network_app_prod}.6.0/24",
    "${var.ip_network_app_prod}.7.0/24",
    "${var.ip_network_app_prod}.8.0/24",
    "${var.ip_network_app_prod}.9.0/24",
    "${var.ip_network_app_prod}.10.0/24"
  ]
  tgw_subnets = [
    "${var.ip_network_app_prod}.11.0/28",
    "${var.ip_network_app_prod}.11.16/28"
  ]
}

