<div align="center">
<img src="coalfire_logo.png" width="200">
</div>

# aws-network-firewall

The Network Firewall filters perimeter traffic at the VPC.

In current VPC module implementation, traffic to the internet in the public subnet is sent to the NFW endpoint instead of directly to the Internet Gateway.

## Usage
Module call (variables as part of the call to the parent VPC module):
```
### Network Firewall ###
deploy_aws_nfw                        = true
aws_nfw_prefix                        = var.resource_prefix
aws_nfw_name                          = "mvp-test-nfw"
aws_nfw_stateless_rule_group          = local.stateless_rule_group_shrd_svcs
aws_nfw_fivetuple_stateful_rule_group = local.fivetuple_rule_group_shrd_svcs
aws_nfw_domain_stateful_rule_group    = local.domain_stateful_rule_group_shrd_svcs
aws_nfw_suricata_stateful_rule_group  = local.suricata_rule_group_shrd_svcs
nfw_kms_key_id                        = aws_kms_key.nfw_key.arn

# When deploying NFW, firewall_subnets must be specified
firewall_subnets       = local.firewall_subnets
firewall_subnet_suffix = "firewall"
```

NFW Policies (in root module):
```
locals {
  rdp_remote_access_policy_shrd_svcs = flatten([
    for k, subnet in local.public_subnets : [
      for index, cidr in var.cidrs_for_remote_access : {
        description           = "All Ingress RDP traffic"
        protocol              = "TCP"
        source_ipaddress      = cidr
        source_port           = "ANY"
        direction             = "FORWARD"
        destination_ipaddress = subnet
        destination_port      = 3389
        sid                   = k + index + 1
        actions = {
          type = "pass"
        }
      }
    ]
  ])

  ssh_remote_access_policy_shrd_svcs = flatten([
    for k, subnet in local.public_subnets : [
      for index, cidr in var.cidrs_for_remote_access : {
        description           = "All Ingress SSH traffic"
        protocol              = "SSH"
        source_ipaddress      = cidr
        source_port           = "ANY"
        direction             = "FORWARD"
        destination_ipaddress = subnet
        destination_port      = 22
        sid                   = k + index + 1
        actions = {
          type = "pass"
        }
      }
    ]
  ])

  domain_stateful_rule_group_shrd_svcs = [
    {
      capacity    = 1000
      name        = "GoogleBlock"
      description = "Stateful rule blocking google.com"
      domain_list = [".cnn.com", ".google.com"]
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

  stateless_rule_group_shrd_svcs = [
    {
      name        = "STATELESSEGRESSWEB"
      capacity    = 1000
      description = "Stateless rule to internet from VPCs"
      rule_config = [
        {
          protocols_number      = [6]
          source_ipaddress      = var.mgmt_vpc_cidr
          source_to_port        = "ANY"
          destination_to_port   = "ANY"
          destination_ipaddress = "0.0.0.0/0"
          tcp_flag = {
            flags = ["SYN"]
            masks = ["SYN", "ACK"]
          }
          actions = {
            type = "pass"
          }
        }
        ]
    },
    {
      name        = "STATELESSRDPBASTION"
      capacity    = 1000
      description = "Stateless rule to allow RDP to Windows Bastion"
      rule_config = [
        for index, cidr in var.cidrs_for_remote_access : {
          protocols_number      = [6]
          source_ipaddress      = cidr
          source_to_port        = 3389
          destination_to_port   = 3389
          destination_ipaddress = var.mgmt_vpc_cidr
          tcp_flag = {
            flags = ["SYN"]
            masks = ["SYN", "ACK"]
          }
          actions = {
            type = "pass"
          }
        }
      ]
    },
    {
      name        = "STATELESSSSHBASTION"
      capacity    = 1000
      description = "Stateless rule to allow SSH to Linux Bastion"
      rule_config = [
        for index, cidr in var.cidrs_for_remote_access : {
          protocols_number      = [6]
          source_ipaddress      = cidr
          source_to_port        = 22
          destination_to_port   = 22
          destination_ipaddress = var.mgmt_vpc_cidr
          tcp_flag = {
            flags = ["SYN"]
            masks = ["SYN", "ACK"]
          }
          actions = {
            type = "pass"
          }
        }
      ]
    }
  ]

  suricata_rule_group_shrd_svcs = [
    {
      capacity    = 1000
      name        = "SURICATARULES"
      description = "Stateful rules with suricta type"
      rules_file  = "./test.rules.json"
    }
  ]

}

```

test.rules.json file (in calling root module):
```
drop tls any any -> $EXTERNAL_NET any (tls.sni; content: ".cnn.com"; startswith; nocase; endswith; msg: "matching TLS denylisted FQDNs"; priority: 1; flow:to_server, established; sid: 1; rev:1;)
drop http any any -> $EXTERNAL_NET any (http.host; content: ".google.com"; startswith; endswith; msg: "matching HTTP denylisted FQDNs"; priority: 1; flow: to_server, established; sid: 3; rev: 1;)
```

Rule group variables are lists of objects.  The variables can be further inspected to determine what parameters and types are expected.  Stateless rule groups are dynamically given a priority from the top-down (start at 0 at the top, then increment by 1).

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.nfw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_networkfirewall_firewall.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall) | resource |
| [aws_networkfirewall_firewall_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy) | resource |
| [aws_networkfirewall_logging_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_logging_configuration) | resource |
| [aws_networkfirewall_rule_group.domain_stateful_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.fivetuple_stateful_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.stateless_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |
| [aws_networkfirewall_rule_group.suricata_stateful_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudwatch_log_group_kms_key_id"></a> [cloudwatch\_log\_group\_kms\_key\_id](#input\_cloudwatch\_log\_group\_kms\_key\_id) | Customer KMS Key id for Cloudwatch Log encryption | `string` | n/a | yes |
| <a name="input_cloudwatch_log_group_retention_in_days"></a> [cloudwatch\_log\_group\_retention\_in\_days](#input\_cloudwatch\_log\_group\_retention\_in\_days) | Number of days to retain Cloudwatch logs | `number` | `365` | no |
| <a name="input_delete_protection"></a> [delete\_protection](#input\_delete\_protection) | Whether or not to enable deletion protection of NFW | `bool` | `true` | no |
| <a name="input_description"></a> [description](#input\_description) | Description for the resources | `string` | `""` | no |
| <a name="input_domain_stateful_rule_group"></a> [domain\_stateful\_rule\_group](#input\_domain\_stateful\_rule\_group) | Config for domain type stateful rule group | <pre>list(object({<br>    name        = string<br>    description = string<br>    capacity    = number<br>    domain_list = list(string)<br>    actions     = string<br>    protocols   = list(string)<br>    rules_file  = optional(string, "")<br>    rule_variables = optional(object({<br>      ip_sets = list(object({<br>        key    = string<br>        ip_set = list(string)<br>      }))<br>      port_sets = list(object({<br>        key       = string<br>        port_sets = list(string)<br>      }))<br>      }), {<br>      ip_sets   = []<br>      port_sets = []<br>    })<br>  }))</pre> | `[]` | no |
| <a name="input_firewall_name"></a> [firewall\_name](#input\_firewall\_name) | firewall name | `string` | `"example"` | no |
| <a name="input_firewall_policy_change_protection"></a> [firewall\_policy\_change\_protection](#input\_firewall\_policy\_change\_protection) | (Option) A boolean flag indicating whether it is possible to change the associated firewall policy | `string` | `false` | no |
| <a name="input_fivetuple_stateful_rule_group"></a> [fivetuple\_stateful\_rule\_group](#input\_fivetuple\_stateful\_rule\_group) | Config for 5-tuple type stateful rule group | <pre>list(object({<br>    name        = string<br>    description = string<br>    capacity    = number<br>    rule_config = list(object({<br>      description           = string<br>      protocol              = string<br>      source_ipaddress      = string<br>      source_port           = string<br>      direction             = string<br>      destination_port      = string<br>      destination_ipaddress = string<br>      sid                   = number<br>      actions               = map(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_nfw_kms_key_id"></a> [nfw\_kms\_key\_id](#input\_nfw\_kms\_key\_id) | NFW KMS Key Id for encryption | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The description for each environment, ie: bin-dev | `string` | n/a | yes |
| <a name="input_stateful_managed_rule_groups_arns"></a> [stateful\_managed\_rule\_groups\_arns](#input\_stateful\_managed\_rule\_groups\_arns) | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy#action | `list(string)` | `[]` | no |
| <a name="input_stateless_default_actions"></a> [stateless\_default\_actions](#input\_stateless\_default\_actions) | Default stateless Action | `string` | `"forward_to_sfe"` | no |
| <a name="input_stateless_fragment_default_actions"></a> [stateless\_fragment\_default\_actions](#input\_stateless\_fragment\_default\_actions) | Default Stateless action for fragmented packets | `string` | `"forward_to_sfe"` | no |
| <a name="input_stateless_rule_group"></a> [stateless\_rule\_group](#input\_stateless\_rule\_group) | Config for stateless rule group | <pre>list(object({<br>    name        = string<br>    description = string<br>    capacity    = number<br>    rule_config = list(object({<br>      protocols_number      = list(number)<br>      source_ipaddress      = string<br>      source_to_port        = string<br>      destination_to_port   = string<br>      destination_ipaddress = string<br>      tcp_flag = object({<br>        flags = list(string)<br>        masks = list(string)<br>      })<br>      actions = map(string)<br>    }))<br>  }))</pre> | `[]` | no |
| <a name="input_subnet_change_protection"></a> [subnet\_change\_protection](#input\_subnet\_change\_protection) | (Optional) A boolean flag indicating whether it is possible to change the associated subnet(s) | `string` | `false` | no |
| <a name="input_subnet_mapping"></a> [subnet\_mapping](#input\_subnet\_mapping) | Subnet ids mapping to have individual firewall endpoint | `list(string)` | n/a | yes |
| <a name="input_suricata_stateful_rule_group"></a> [suricata\_stateful\_rule\_group](#input\_suricata\_stateful\_rule\_group) | Config for Suricata type stateful rule group | <pre>list(object({<br>    name        = string<br>    description = string<br>    capacity    = number<br>    rules_file  = optional(string, "")<br>    rule_variables = optional(object({<br>      ip_sets = list(object({<br>        key    = string<br>        ip_set = list(string)<br>      }))<br>      port_sets = list(object({<br>        key       = string<br>        port_sets = list(string)<br>      }))<br>      }), {<br>      ip_sets   = []<br>      port_sets = []<br>    })<br>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags for the resources | `map(any)` | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | Created Network Firewall ARN from network\_firewall module |
| <a name="output_endpoint_id"></a> [endpoint\_id](#output\_endpoint\_id) | Created Network Firewall endpoint id |
| <a name="output_id"></a> [id](#output\_id) | Created Network Firewall ID from network\_firewall module |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
