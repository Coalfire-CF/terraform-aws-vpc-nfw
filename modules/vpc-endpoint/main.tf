# Create security groups for VPC endpoints
resource "aws_security_group" "endpoint_sg" {
  for_each = var.create_vpc_endpoints ? var.security_groups : {}

  name        = each.value.name
  description = each.value.description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.value.name
    }
  )
}

# Create ingress rules for security groups
resource "aws_security_group_rule" "ingress" {
  for_each = var.create_vpc_endpoints ? {
    for rule in flatten([
      for sg_key, sg in var.security_groups : [
        for rule_idx, rule in sg.ingress_rules : {
          sg_key    = sg_key
          rule_idx  = rule_idx
          rule      = rule
        }
      ]
    ]) : "${rule.sg_key}_ingress_${rule.rule_idx}" => rule
  } : {}

  security_group_id = aws_security_group.endpoint_sg[each.value.sg_key].id
  type              = "ingress"
  from_port         = each.value.rule.from_port
  to_port           = each.value.rule.to_port
  protocol          = each.value.rule.protocol
  description       = each.value.rule.description

  cidr_blocks       = length(each.value.rule.cidr_blocks) > 0 ? each.value.rule.cidr_blocks : null
  ipv6_cidr_blocks  = length(each.value.rule.ipv6_cidr_blocks) > 0 ? each.value.rule.ipv6_cidr_blocks : null
  self              = each.value.rule.self ? true : null

  # Only include security_groups if specified
  security_groups   = length(each.value.rule.security_groups) > 0 ? each.value.rule.security_groups : null
}

# Create egress rules for security groups
resource "aws_security_group_rule" "egress" {
  for_each = var.create_vpc_endpoints ? {
    for rule in flatten([
      for sg_key, sg in var.security_groups : [
        for rule_idx, rule in sg.egress_rules : {
          sg_key    = sg_key
          rule_idx  = rule_idx
          rule      = rule
        }
      ]
    ]) : "${rule.sg_key}_egress_${rule.rule_idx}" => rule
  } : {}

  security_group_id = aws_security_group.endpoint_sg[each.value.sg_key].id
  type              = "egress"
  from_port         = each.value.rule.from_port
  to_port           = each.value.rule.to_port
  protocol          = each.value.rule.protocol
  description       = each.value.rule.description

  cidr_blocks       = length(each.value.rule.cidr_blocks) > 0 ? each.value.rule.cidr_blocks : null
  ipv6_cidr_blocks  = length(each.value.rule.ipv6_cidr_blocks) > 0 ? each.value.rule.ipv6_cidr_blocks : null
  self              = each.value.rule.self ? true : null

  # Only include security_groups if specified
  security_groups   = length(each.value.rule.security_groups) > 0 ? each.value.rule.security_groups : null
}

# Get VPC endpoint service details if needed
data "aws_vpc_endpoint_service" "this" {
  for_each = var.create_vpc_endpoints ? merge(
    {
      for endpoint_key, endpoint in var.vpc_endpoints :
        endpoint_key => endpoint if endpoint.service_name == null
    },
    # Add FIPS variants when enabled
    var.enable_fips_endpoints ? {
      for endpoint_key, endpoint in var.vpc_endpoints :
        "${endpoint_key}-fips" => endpoint if endpoint.service_name == null &&
        contains([
          # Standard AWS services that support FIPS endpoints via PrivateLink
          # Based on: https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html
          "access-analyzer", "acm", "acm-pca", "api.ecr", "api.sagemaker", "application-autoscaling",
          "appsync", "athena", "autoscaling", "autoscaling-plans", "backup", "batch", "cassandra",
          "clouddirectory", "cloudformation", "cloudtrail", "codebuild", "codecommit", "codedeploy",
          "codepipeline", "codestar-connections", "config", "databrew", "dataexchange", "datasync",
          "dms", "drs", "ds", "ec2", "ec2messages", "ecr.api", "ecr.dkr", "ecs", "ecs-agent",
          "ecs-telemetry", "elasticbeanstalk", "elasticbeanstalk-health", "elasticfilesystem",
          "elasticloadbalancing", "elasticmapreduce", "email-smtp", "events", "execute-api",
          "firehose", "fis", "fsx", "glacier", "glue", "grafana", "greengrass", "groundstation",
          "healthlake", "inspector", "iot", "iot.data", "iotwireless", "kafka", "kafka-bootstrap",
          "kinesis-firehose", "kinesis-streams", "kms", "lakeformation", "lambda", "license-manager",
          "logs", "macie2", "managedblockchain", "monitoring", "notebook", "outposts", "profile",
          "qldb.session", "rds", "rds-data", "redshift", "redshift-data", "rekognition", "repostspace",
          "resource-groups", "runtime.lex", "runtime-v2.lex", "runtime.sagemaker", "s3", "sagemaker.api",
          "secretsmanager", "securityhub", "servicecatalog", "servicecatalog-appregistry", "sms", "sns",
          "sqs", "ssm", "ssmmessages", "states", "storagegateway", "sts", "synthetics", "textract",
          "transcribe", "transfer", "transfer.server", "wafv2", "workspaces"
        ], endpoint_key)
    } : {}
  ) : {}

  service = replace(each.key, "-fips", "")

  # If we're looking up the service, we need to filter by the right service type
  filter {
    name   = "service-type"
    values = [var.vpc_endpoints[replace(each.key, "-fips", "")].service_type]
  }

  # Use FIPS filter when looking up FIPS endpoints
  dynamic "filter" {
    for_each = endswith(each.key, "-fips") ? [1] : []
    content {
      name   = "service-name"
      values = ["*fips*"]
    }
  }
}

locals {
  # Map of endpoint SGs - combine existing SGs with newly created ones
  endpoint_security_groups = {
    for endpoint_key, endpoint in var.vpc_endpoints :
      endpoint_key => concat(
        endpoint.security_group_ids,
        [
          for sg_key, sg in var.security_groups :
            aws_security_group.endpoint_sg[sg_key].id
            if contains(keys(var.security_groups), "${endpoint_key}_sg")
        ]
      )
      if var.create_vpc_endpoints
  }
}

# Create VPC endpoints
resource "aws_vpc_endpoint" "this" {
  for_each = var.create_vpc_endpoints ? var.vpc_endpoints : {}

  vpc_id       = var.vpc_id
  service_name = each.value.service_name != null ? each.value.service_name : (
    startswith(each.key, "s3") || startswith(each.key, "dynamodb") ?
      "com.amazonaws.${data.aws_region.current.name}.${each.key}" :
      var.enable_fips_endpoints && can(data.aws_vpc_endpoint_service.this["${each.key}-fips"]) ?
        data.aws_vpc_endpoint_service.this["${each.key}-fips"].service_name :
        data.aws_vpc_endpoint_service.this[each.key].service_name
  )
  vpc_endpoint_type = each.value.service_type

  # Interface-specific settings
  private_dns_enabled = each.value.service_type == "Interface" ? each.value.private_dns_enabled : null
  security_group_ids  = each.value.service_type == "Interface" ? local.endpoint_security_groups[each.key] : null
  subnet_ids          = each.value.service_type == "Interface" ? (
    each.value.subnet_ids != null ? each.value.subnet_ids : var.subnet_ids
  ) : null

  # Gateway-specific settings
  route_table_ids     = each.value.service_type == "Gateway" ? var.route_table_ids : null

  # GatewayLoadBalancer-specific settings
  ip_address_type     = each.value.service_type == "GatewayLoadBalancer" ? each.value.ip_address_type : null

  # Common settings
  auto_accept         = each.value.auto_accept
  policy              = each.value.policy

  tags = merge(
    var.tags,
    each.value.tags,
    {
      Name = each.key
    }
  )
}

data "aws_region" "current" {}

# Associate with private route tables if enabled
resource "aws_vpc_endpoint_route_table_association" "private_route_tables" {
  for_each = var.create_vpc_endpoints && var.associate_with_private_route_tables ? {
    for pair in setproduct(
      [for ep_key, ep in aws_vpc_endpoint.this : ep.id if ep.vpc_endpoint_type == "Gateway"],
      var.route_table_ids
    ) : "${pair[0]}_${pair[1]}" => {
      endpoint_id = pair[0]
      rtb_id     = pair[1]
    }
  } : {}

  vpc_endpoint_id = each.value.endpoint_id
  route_table_id  = each.value.rtb_id
}

# Associate with public route tables if enabled
resource "aws_vpc_endpoint_route_table_association" "public_route_tables" {
  for_each = var.create_vpc_endpoints && var.associate_with_public_route_tables ? {
    for pair in setproduct(
      [for ep_key, ep in aws_vpc_endpoint.this : ep.id if ep.vpc_endpoint_type == "Gateway"],
      var.public_route_table_ids
    ) : "${pair[0]}_${pair[1]}" => {
      endpoint_id = pair[0]
      rtb_id     = pair[1]
    }
  } : {}

  vpc_endpoint_id = each.value.endpoint_id
  route_table_id  = each.value.rtb_id
}
