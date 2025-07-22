locals {
  fivetuple_rule_group = [
    {
      name        = "EGRESSWEB"
      capacity    = 1000
      description = "Stateful rule to internet from VPCs"
      rule_config = [
        {
          description           = "All WEB Internet traffic"
          protocol              = "TCP"
          source_ipaddress      = module.mgmt_vpc.vpc_cidr_block
          source_port           = "ANY"
          direction             = "FORWARD"
          destination_ipaddress = "ANY"
          destination_port      = "ANY"
          sid                   = 1
          actions = {
            type = "pass"
          }
        },
        {
          description           = "All HTTP Internet traffic"
          protocol              = "TCP"
          source_ipaddress      = module.mgmt_vpc.vpc_cidr_block
          source_port           = "ANY"
          direction             = "FORWARD"
          destination_ipaddress = "ANY"
          destination_port      = "ANY"
          sid                   = 2
          actions = {
            type = "pass"
          }
        }
      ]
    },
    {
      name        = "EGRESSSSH"
      capacity    = 1000
      description = "Stateful rule to SSH to VPCs"
      rule_config = [
        {
          description           = "All SSH traffic"
          protocol              = "TCP"
          source_ipaddress      = module.mgmt_vpc.vpc_cidr_block
          source_port           = "ANY"
          direction             = "FORWARD"
          destination_ipaddress = "ANY"
          destination_port      = 22
          sid                   = 2
          actions = {
            type = "pass"
          }
        }
      ]
    },
    {
      name        = "EGRESSSSHRDP"
      capacity    = 1000
      description = "Stateful rule to RDP to VPCs"
      rule_config = [
        {
          description           = "All RDP traffic"
          protocol              = "TCP"
          source_ipaddress      = module.mgmt_vpc.vpc_cidr_block
          source_port           = "ANY"
          direction             = "FORWARD"
          destination_ipaddress = "ANY"
          destination_port      = 3389
          sid                   = 1
          actions = {
            type = "pass"
          }
        }
      ]
    },
    {
      name        = "INGRESSRDP"
      capacity    = 1000
      description = "Stateful rule to RDP to WINBastions"

      rule_config = local.rdp_remote_access_policy_shrd_svcs
    },
    {
      name        = "INGRESSSSH"
      capacity    = 1000
      description = "Stateful rule to SSH to LINBastions"

      rule_config = local.ssh_remote_access_policy_shrd_svcs
    }
  ]
  suricata_rule_group_shrd_svcs = [
    {
      capacity    = 1000
      name        = "SuricataDenyAll"
      description = "DenyAllRules"
      rules_file  = file("./suricata.json")
    }
  ]
  rdp_remote_access_policy_shrd_svcs = flatten([
    for index, cidr in var.cidrs_for_remote_access : {
      description           = "All Ingress RDP traffic"
      protocol              = "TCP"
      source_ipaddress      = cidr
      source_port           = "ANY"
      direction             = "FORWARD"
      destination_ipaddress = module.mgmt_vpc.vpc_cidr_block
      destination_port      = 3389
      sid                   = index + 1
      actions = {
        type = "pass"
      }
    }

  ])

  ssh_remote_access_policy_shrd_svcs = flatten([
    for index, cidr in var.cidrs_for_remote_access : {
      description           = "All Ingress SSH traffic"
      protocol              = "SSH"
      source_ipaddress      = cidr
      source_port           = "ANY"
      direction             = "FORWARD"
      destination_ipaddress = module.mgmt_vpc.vpc_cidr_block
      destination_port      = 22
      sid                   = index + 1
      actions = {
        type = "pass"
      }
    }

  ])
}