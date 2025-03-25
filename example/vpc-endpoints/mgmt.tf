##############################################
# Example usage of VPC module with endpoints
##############################################

module "mgmt_vpc" {
  source = "../../."
  providers = {
    aws = aws.mgmt
  }

  name = "${var.resource_prefix}-mgmt"

  delete_protection = var.delete_protection

  cidr = var.mgmt_vpc_cidr

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

  tgw_subnets = local.tgw_subnets
  tgw_subnet_tags = {
    "0" = "TGW"
    "1" = "TGW"
    "2" = "TGW"
  }

  public_subnets       = local.public_subnets
  public_subnet_suffix = "dmz"

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
  aws_nfw_name                          = "mvp-test-nfw"
  aws_nfw_fivetuple_stateful_rule_group = local.fivetuple_rule_group
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
  enable_fips_endpoints  = true  # Use FIPS endpoints in GovCloud region

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

    # SSM Interface endpoint
    ssm = {
      service_type        = "Interface"
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-ssm-endpoint" }
    }

    # SSM Messages Interface endpoint
    ssmmessages = {
      service_type        = "Interface"
      service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-ssmmessages-endpoint" }
    }

    # EC2 Messages Interface endpoint
    ec2messages = {
      service_type        = "Interface"
      service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-ec2messages-endpoint" }
    }

    # KMS Interface endpoint (for encryption operations)
    kms = {
      service_type        = "Interface"
      service_name        = "com.amazonaws.${var.aws_region}.kms"
      private_dns_enabled = true
      tags                = { Name = "${var.resource_prefix}-kms-endpoint" }
    }
  }

  # Define security groups for VPC endpoints
  vpc_endpoint_security_groups = {
    # Security group for SSM-related endpoints
    ssm_endpoints_sg = {
      name        = "${var.resource_prefix}-ssm-endpoints-sg"
      description = "Security group for SSM and related VPC endpoints"
      ingress_rules = [
        {
          description = "HTTPS from VPC"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = [var.mgmt_vpc_cidr]
        }
      ]
      egress_rules = [
        {
          description = "Allow all outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      tags = {
        Name = "${var.resource_prefix}-ssm-endpoints-sg"
      }
    },

    # Security group for KMS endpoint
    kms_endpoint_sg = {
      name        = "${var.resource_prefix}-kms-endpoint-sg"
      description = "Security group for KMS VPC endpoint"
      ingress_rules = [
        {
          description = "HTTPS from VPC"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = [var.mgmt_vpc_cidr]
        }
      ]
      egress_rules = [
        {
          description = "Allow all outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      tags = {
        Name = "${var.resource_prefix}-kms-endpoint-sg"
      }
    }
  }

  tags = {
    Owner       = var.resource_prefix
    Environment = "mgmt"
    createdBy   = "terraform"
  }
}