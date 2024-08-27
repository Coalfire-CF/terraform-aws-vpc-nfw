locals {

  fivetuple_rule_group = [
    {
      name        = "EGRESSWEB"
      capacity    = 1000
      description = "Stateful rule to internet from VPCs"
      rule_config = [
        {
          description           = "All WEB Internet traffic"
          protocol              = "IP"
          source_ipaddress      = module.shared_vpc.vpc_cidr_block
          source_port           = "ANY"
          direction             = "FORWARD"
          destination_ipaddress = "ANY"
          destination_port      = "ANY"
          sid                   = 1
          actions               = {
            type = "pass"
          }
        }
      ]
    }
  ]

}
