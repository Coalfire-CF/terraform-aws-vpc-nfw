module "mgmt_subnet_addrs" {
  source  = "hashicorp/subnets/cidr"
  version = "v1.0.0"

  base_cidr_block = var.mgmt_vpc_cidr
  networks = [
    {
      name     = "mvptest-firewall-1a"
      new_bits = 8
    },
    {
      name     = "mvptest-firewall-1b"
      new_bits = 8
    },
    {
      name     = "mvptest-firewall-1c"
      new_bits = 8
    },
    {
      name     = "mvptest-public-1a"
      new_bits = 8
    },
    {
      name     = "mvptest-public-1b"
      new_bits = 8
    },
    {
      name     = "mvptest-public-1c"
      new_bits = 8
    },
    {
      name     = "mvptest-compute-1a"
      new_bits = 8
    },
    {
      name     = "mvptest-compute-1b"
      new_bits = 8
    },
    {
      name     = "mvptest-compute-1c"
      new_bits = 8
    },
    {
      name     = "mvptest-private-1a"
      new_bits = 8
    },
    {
      name     = "mvptest-private-1b"
      new_bits = 8
    },
    {
      name     = "mvptest-private-1c"
      new_bits = 8
    }
  ]
}
