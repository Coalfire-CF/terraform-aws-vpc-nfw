locals {
  rdp_remote_access_policy_shrd_svcs = flatten([
      for index, cidr in var.cidrs_for_remote_access : {
        description           = "All Ingress RDP traffic"
        protocol              = "TCP"
        source_ipaddress      = cidr
        source_port           = "ANY"
        direction             = "FORWARD"
        destination_ipaddress = var.mgmt_vpc_cidr
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
        destination_ipaddress = var.mgmt_vpc_cidr
        destination_port      = 22
        sid                   = index + 1
        actions = {
          type = "pass"
        }
      }

  ])

  domain_stateful_rule_group_shrd_svcs = [
    {
      capacity    = 1000
      name        = "4ChanBlock"
      description = "Stateful rule blocking 4chan.com"
      domain_list = [".4chan.com"]
      actions     = "DENYLIST"
      protocols   = ["HTTP_HOST", "TLS_SNI"]
      rule_variables = {
        ip_sets = [
          {
            key    = "HOME_NET"
            ip_set = [var.mgmt_vpc_cidr]
          },
          {
            key    = "EXTERNAL_HOST"
            ip_set = ["0.0.0.0/0"]
          }
        ]
        port_sets = [
          {
            key       = "HTTP_PORTS"
            port_sets = ["443", "80"]
          }
        ]
      }
    },
  ]


  fivetuple_rule_group_shrd_svcs = [
    {
      name        = "EGRESSWEB"
      capacity    = 1000
      description = "Stateful rule to internet from VPCs"
      rule_config = [
        {
          description           = "All WEB Internet traffic"
          protocol              = "TCP"
          source_ipaddress      = var.mgmt_vpc_cidr
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
          source_ipaddress      = var.mgmt_vpc_cidr
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
      name        = "EGRESSSSHRDP"
      capacity    = 1000
      description = "Stateful rule to RDP/SSH to VPCs"
      rule_config = [
        {
          description           = "All RDP traffic"
          protocol              = "TCP"
          source_ipaddress      = var.mgmt_vpc_cidr
          source_port           = "ANY"
          direction             = "FORWARD"
          destination_ipaddress = "ANY"
          destination_port      = 3389
          sid                   = 1
          actions = {
            type = "pass"
          }
        },
        {
          description           = "All SSH traffic"
          protocol              = "TCP"
          source_ipaddress      = var.mgmt_vpc_cidr
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

  #not required - example ruleset
  suricata_rule_group_shrd_svcs = [
    {
      capacity    = 1000
      name        = "SURICATARULES"
      description = "Stateful rules with suricta type"
      rules_file  = "./test.rules.json"
    }
  ]


}