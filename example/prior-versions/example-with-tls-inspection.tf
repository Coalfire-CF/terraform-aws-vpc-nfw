module "mgmt_vpc" {
  source = "git::https://github.com/Coalfire-CF/terraform-aws-vpc-nfw.git?ref=vx.x.x"

  name = "example-mgmt"
  cidr = "10.1.0.0/16"
  azs  = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]

  single_nat_gateway     = false
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true

  flow_log_destination_type              = "cloud-watch-logs"
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_kms_key_id        = "arn:aws-us-gov:kms:your-kms-key-arn"

  ### Network Firewall ###
  deploy_aws_nfw    = true
  delete_protection = true
  aws_nfw_prefix    = "example"
  aws_nfw_name      = "example-nfw"
  nfw_kms_key_id    = "arn:aws-us-gov:kms:your-kms-key-arn"

  # Reference example directory for these values, as they are too large to show here
  aws_nfw_fivetuple_stateful_rule_group = local.fivetuple_rule_group
  aws_nfw_suricata_stateful_rule_group  = local.suricata_rule_group_shrd_svcs

  # When deploying NFW, firewall_subnets must be specified
  firewall_subnets       = local.firewall_subnets
  firewall_subnet_suffix = "firewall"

  # TLS Outbound Inspection (Optional)
  enable_tls_inspection = var.enable_tls_inspection # deploy_aws_nfw must be set to true to enable this
  tls_cert_arn          = var.tls_cert_arn
  tls_destination_cidrs = var.tls_destination_cidrs # Set these to the NAT gateways to filter outbound traffic without affecting the hosted VPN

  ### VPC Endpoints ### (Optional)
  create_vpc_endpoints = true

  # Control where gateway endpoints are associated
  associate_with_private_route_tables = true  # Associate with private subnets (default)
  associate_with_public_route_tables  = false # Don't associate with public subnets

  vpc_endpoints = {
    # S3 Gateway endpoint
    s3 = {
      service_type = "Gateway"
      service_name = "com.amazonaws.${var.aws_region}.s3"
      tags         = { Name = "${var.resource_prefix}-s3-gateway-endpoint" }
    }

    # DynamoDB Gateway endpoint
    dynamodb = {
      service_type = "Gateway"
      service_name = "com.amazonaws.${var.aws_region}.dynamodb"
      tags         = { Name = "${var.resource_prefix}-dynamodb-endpoint" }
    }

    # KMS Interface endpoint (for encryption operations)
    kms = {
      service_type        = "Interface"
      service_name        = "com.amazonaws.${var.aws_region}.kms-fips"
      subnet_ids          = [module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1a"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1b"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1c"]]
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-kms-endpoint" }
    }

    # SSM Interface endpoint
    ssm = {
      service_type        = "Interface"
      service_name        = "com.amazonaws.${var.aws_region}.ssm"
      subnet_ids          = [module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1a"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1b"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1c"]]
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-ssm-endpoint" }
    }

    # SSM Messages Interface endpoint
    ssmmessages = {
      service_type        = "Interface"
      service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
      subnet_ids          = [module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1a"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1b"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1c"]]
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-ssmmessages-endpoint" }
    }

    # EC2 Messages Interface endpoint
    ec2messages = {
      service_type        = "Interface"
      service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
      subnet_ids          = [module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1a"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1b"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1c"]]
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-ec2messages-endpoint" }
    }

    # Logs Interface endpoint
    logs = {
      service_type        = "Interface"
      service_name        = "com.amazonaws.${var.aws_region}.logs"
      subnet_ids          = [module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1a"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1b"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1c"]]
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-logs-endpoint" }
    }

    dockerregistry = {
      service_type        = "Interface"
      service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
      subnet_ids          = [module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1a"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1b"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1c"]]
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-ecr-dkr" }
    }

    ecr = {
      service_type        = "Interface"
      service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
      subnet_ids          = [module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1a"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1b"], module.mgmt_vpc.private_subnets["vpc-compute-us-gov-west-1c"]]
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-ecr-api" }
    }

  }

  # Define security groups for VPC endpoints
  vpc_endpoint_security_groups = {
    common_sg = {
      name        = "common-endpoint-sg"
      description = "Common security group for all VPC endpoint"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["${var.ip_network_fedramp_mgmt}.0.0/16"]
        }
      ]

      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
  }

  /* Add Additional tags here */
  tags = {
    Owner       = var.resource_prefix
    Environment = "mgmt"
    createdBy   = "terraform"
  }
}
