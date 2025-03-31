# AWS VPC Endpoint Submodule

This submodule extends the main AWS VPC module to support the creation and management of VPC endpoints. It allows you to easily create and configure multiple VPC endpoints of different types (Gateway, Interface, GatewayLoadBalancer) within your VPC.

## Features

- Support for all VPC endpoint types: Gateway, Interface, and GatewayLoadBalancer
- FIPS endpoint support for compliant AWS services (important for GovCloud and regulated environments)
- Granular control over endpoint associations with route tables (private vs public)
- Create dedicated security groups for Interface endpoints
- Configure security group rules for ingress and egress traffic
- Automatic service name resolution using AWS VPC endpoint service data source
- Control endpoint creation with a single flag
- Apply tags to all resources

## Usage

### Integration with Main VPC Module

This submodule is designed to be called from the main VPC module. The main module should pass the necessary resources like VPC ID, subnet IDs, and route table IDs to this submodule.

```hcl
module "vpc_endpoints" {
  source = "./modules/vpc-endpoint"
  
  create_vpc_endpoints = var.create_vpc_endpoints
  vpc_id               = aws_vpc.this.id
  subnet_ids           = [for subnet in aws_subnet.private : subnet.id]
  route_table_ids      = concat(
    [for rt in aws_route_table.private : rt.id],
    [for rt in aws_route_table.public : rt.id]
  )
  
  vpc_endpoints        = var.vpc_endpoints
  security_groups      = var.vpc_endpoint_security_groups
  
  tags                 = var.tags
}
```

### Example

Here's how to use the VPC module with VPC endpoints enabled:

```hcl
module "vpc" {
  source = "path/to/vpc/module"
  
  name                   = "example-vpc"
  cidr                   = "10.0.0.0/16"
  
  azs                    = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets        = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets         = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  
  # Enable VPC endpoints
  create_vpc_endpoints   = true
  enable_fips_endpoints  = true  # Use FIPS endpoints where available
  
  # Control route table associations
  associate_endpoints_with_private_route_tables = true  # Default behavior
  associate_endpoints_with_public_route_tables = false  # Don't associate with public subnets
  
  # Define VPC endpoints
  vpc_endpoints = {
    # S3 Gateway endpoint
    s3 = {
      service_type = "Gateway"
      service_name = "com.amazonaws.us-east-1.s3"
    }
    
    # SSM Interface endpoint
    ssm = {
      service_type        = "Interface"
      private_dns_enabled = true
    }
  }
  
  # Define security groups for VPC endpoints
  vpc_endpoint_security_groups = {
    ssm_sg = {
      name        = "ssm-endpoint-sg"
      description = "Security group for SSM VPC endpoint"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]
        }
      ]
    }
  }
  vpc_endpoints = { 
    s3 = {
      service_type = "Gateway",
      auto_accept = true, 
      service_name =  "com.amazonaws.us-gov-west-1.s3",
      tags = {
        Name = "test-s3-endpoint"
      },
    },
    dynamodb = {
      service_type = "Gateway",
      auto_accept = true, 
      service_name =  "com.amazonaws.us-gov-west-1.dynamodb",
      tags = {
        Name = "test-dynamodb-endpoint"
      },
    },
    secretsmanager = {
      service_type = "Interface",
      auto_accept = true, 
      service_name =  "com.amazonaws.us-gov-west-1.secretsmanager",
      tags = {
        Name = "test-secretsmanager-endpoint"
      },
    },
    kms-fips = {
      service_type = "Interface",
      auto_accept = true, 
      service_name =  "com.amazonaws.us-gov-west-1.kms-fips",
      tags = {
        Name = "test-kms-endpoint"
      },
    }
  }
   
  vpc_endpoint_security_groups = {
    s3_sg = {
      name        = "test-s3-sg"
      description = "Security group for s3 VPC endpoint"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = [var.mgmt_vpc_cidr]
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
    dynamodb_sg = {
      name        = "test-dynamodb-sg"
      description = "Security group for dynamodb VPC endpoint"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = [var.mgmt_vpc_cidr]
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
    secretsmanager_sg = {
      name        = "test-secretsmanager-sg"
      description = "Security group for secretsmanager VPC endpoint"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = [var.mgmt_vpc_cidr]
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
    kms_sg = {
      name        = "test-kms-sg"
      description = "Security group for kms VPC endpoint"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = [var.mgmt_vpc_cidr]
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

}
```

## Input Variables

### Main Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_vpc_endpoints` | Whether to create VPC endpoints | `bool` | `false` |
| `enable_fips_endpoints` | Whether to use FIPS endpoints where available | `bool` | `false` |
| `associate_with_private_route_tables` | Whether to associate Gateway endpoints with private route tables | `bool` | `true` |
| `associate_with_public_route_tables` | Whether to associate Gateway endpoints with public route tables | `bool` | `false` |
| `vpc_id` | ID of the VPC where endpoints will be created | `string` | n/a |
| `subnet_ids` | List of subnet IDs for interface endpoints | `list(string)` | `[]` |
| `route_table_ids` | List of private route table IDs for gateway endpoints | `list(string)` | `[]` |
| `public_route_table_ids` | List of public route table IDs for gateway endpoints | `list(string)` | `[]` |

### VPC Endpoints Configuration

```hcl
variable "vpc_endpoints" {
  type = map(object({
    service_name        = optional(string)
    service_type        = string
    private_dns_enabled = optional(bool, true)
    auto_accept         = optional(bool, false)
    policy              = optional(string)
    security_group_ids  = optional(list(string), [])
    tags                = optional(map(string), {})
    subnet_ids          = optional(list(string))
    ip_address_type     = optional(string)
  }))
}
```

### Security Groups Configuration

```hcl
variable "security_groups" {
  type = map(object({
    name        = string
    description = optional(string)
    ingress_rules = optional(list(object({
      description      = optional(string)
      from_port        = number
      to_port          = number
      protocol         = string
      cidr_blocks      = optional(list(string), [])
      ipv6_cidr_blocks = optional(list(string), [])
      security_groups  = optional(list(string), [])
      self             = optional(bool, false)
    })), [])
    egress_rules = optional(list(...))
    tags         = optional(map(string), {})
  }))
}
```

## Outputs

| Name | Description |
|------|-------------|
| `vpc_endpoint_ids` | Map of VPC endpoint IDs |
| `vpc_endpoint_dns_entries` | DNS entries for VPC endpoints |
| `security_groups` | Map of security group IDs created for VPC endpoints |

## Notes

1. When `create_vpc_endpoints` is set to `false`, no VPC endpoints will be created regardless of what is defined in the `vpc_endpoints` map.
2. For Gateway endpoints (like S3 and DynamoDB), you must provide `route_table_ids`.
3. For Interface endpoints, you must provide `subnet_ids` and may need security groups.
4. If `service_name` is not provided, the module will attempt to construct it based on the endpoint key and current region.
5. When `enable_fips_endpoints` is set to `true`, the module will attempt to use FIPS-enabled endpoints for applicable services.
6. FIPS endpoints are available for many AWS services but the availability may vary by region, especially in GovCloud.
7. Not all services that support PrivateLink necessarily have FIPS endpoints available - the module will fall back to standard endpoints if FIPS variants are not found.

## Working with FIPS Endpoints

FIPS (Federal Information Processing Standards) endpoints are important for workloads that require FIPS 140-2 compliance. These endpoints are available in specific AWS regions, particularly AWS GovCloud.

To use FIPS endpoints:

1. Set `enable_fips_endpoints = true` when calling the VPC module
2. The module will automatically attempt to find FIPS versions of supported services
3. If a FIPS endpoint is found for a requested service, it will be used instead of the standard endpoint

Example of how FIPS endpoints appear in different regions:
- Standard endpoint: `com.amazonaws.us-east-1.ssm`
- FIPS endpoint: `com.amazonaws.us-east-1.ssm-fips`
- GovCloud FIPS endpoint: `com.amazonaws.us-gov-west-1.ssm-fips`

The module supports FIPS endpoints for all AWS services that offer PrivateLink FIPS endpoints as listed in the [AWS PrivateLink documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html), including but not limited to:

- Systems Manager (SSM)
- Key Management Service (KMS)
- CloudWatch Logs
- CloudWatch Monitoring
- EC2 Messages
- SSM Messages
- Simple Queue Service (SQS)
- Simple Notification Service (SNS)
- Secrets Manager
- Lambda
- And many more...

## Common VPC Endpoint Services

Here are some common AWS services that you might want to create VPC endpoints for:

### Gateway Endpoints
- S3: `com.amazonaws.<region>.s3`
- DynamoDB: `com.amazonaws.<region>.dynamodb`

### Interface Endpoints
- SSM: `com.amazonaws.<region>.ssm`
- EC2: `com.amazonaws.<region>.ec2`
- ECR API: `com.amazonaws.<region>.ecr.api`
- ECR DKR: `com.amazonaws.<region>.ecr.dkr`
- ECS: `com.amazonaws.<region>.ecs`
- Secrets Manager: `com.amazonaws.<region>.secretsmanager`
- CloudWatch Logs: `com.amazonaws.<region>.logs`
- CloudWatch: `com.amazonaws.<region>.monitoring`
- KMS: `com.amazonaws.<region>.kms`
- SQS: `com.amazonaws.<region>.sqs`
- SNS: `com.amazonaws.<region>.sns`
- Systems Manager: `com.amazonaws.<region>.ssm`
- Lambda: `com.amazonaws.<region>.lambda`