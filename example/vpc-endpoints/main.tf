module "vpc" {
  source = "../../" # This should point to your main module

  name = "${var.resource_prefix}-mgmt"

  delete_protection = var.delete_protection

  cidr = var.vpc_cidr

  azs = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1], data.aws_availability_zones.available.names[2]]

  private_subnets = local.private_subnets
  private_subnet_tags = {
    "0" = "Compute"
    "1" = "Compute"
    "2" = "Compute"
    "3" = "Private"
    "4" = "Private"
    "5" = "Private"
  }

  vpce_subnets = local.vpce_subnets
  vpce_subnet_tags = {
    "0" = "vpce"
    "1" = "vpce"
    "2" = "vpce"
  }

  tgw_subnets = local.tgw_subnets
  tgw_subnet_tags = {
    "0" = "TGW"
    "1" = "TGW"
    "2" = "TGW"
  }

  public_subnets       = local.public_subnets
  public_subnet_tags = {
    "0" = "public"
    "1" = "public"
    "2" = "public"
  }

  single_nat_gateway     = false
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false
  enable_dns_hostnames   = true

  flow_log_destination_type              = "cloud-watch-logs"
  cloudwatch_log_group_retention_in_days = 30
  cloudwatch_log_group_kms_key_id        = aws_kms_key.cloudwatch_key.arn

  ### Network Firewall ###
  deploy_aws_nfw                        = var.deploy_aws_nfw
  aws_nfw_prefix                        = var.resource_prefix
  aws_nfw_name                          = "${var.resource_prefix}-nfw"
  aws_nfw_fivetuple_stateful_rule_group = var.aws_nfw_fivetuple_stateful_rule_group
  aws_nfw_stateless_rule_group          = var.aws_nfw_stateless_rule_group
  nfw_kms_key_id                        = aws_kms_key.nfw_key.arn

  # When deploying NFW, firewall_subnets must be specified
  firewall_subnets       = local.firewall_subnets
  firewall_subnet_suffix = "firewall"

  ### TLS Inspection ###
  enable_tls_inspection = var.enable_tls_inspection
  tls_cert_arn          = var.tls_cert_arn
  tls_description       = "TLS Inspection"
  tls_destination_cidrs = var.tls_destination_cidrs

  ### VPC Endpoints ###
  create_vpc_endpoints   = true

  # Control where gateway endpoints are associated
  associate_with_private_route_tables = true  # Associate with private subnets (default)
  associate_with_public_route_tables = false  # Don't associate with public subnets

  vpc_endpoints = {
    # S3 Gateway endpoint
    s3 = {
      service_type        = "Gateway"
      service_name        = "com.amazonaws.${var.aws_region}.s3"
      tags                = { Name = "${var.resource_prefix}-s3-endpoint" }
    }

    # DynamoDB Gateway endpoint
    dynamodb = {
      service_type        = "Gateway"
      service_name        = "com.amazonaws.${var.aws_region}.dynamodb"
      tags                = { Name = "${var.resource_prefix}-dynamodb-endpoint" }
    }

    # KMS Interface endpoint (for encryption operations)
    kms = {
      service_type        = "Interface"
      service_name        = "com.amazonaws.${var.aws_region}.kms-fips"
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-kms-endpoint" }
    }
  }

 # Define a common security group for the VPC endpoints
  vpc_endpoint_security_groups = {
      common_sg = {
        name        = "common-endpoint-sg"
        description = "Common security group for all VPC endpoints"
        ingress_rules = [
          {
            from_port   = 443
            to_port     = 443
            protocol    = "tcp"
            cidr_blocks = ["10.0.0.0/16"] # should just allow your vpc_cidr
          }
        ]
      }
    }

  tags = {
    Owner       = var.resource_prefix
    Environment = "mgmt"
    createdBy   = "terraform"
  }
}

resource "aws_kms_key" "nfw" {
  description             = "KMS key for Network Firewall encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.resource_prefix}-nfw-key"
  }
}

resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.resource_prefix}-cloudwatch-key"
  }
}