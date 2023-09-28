locals {
  flow_log_destination_arn = var.flow_log_destination_type == "cloud-watch-logs" ? try(aws_cloudwatch_log_group.this[0].arn, null) : var.flow_log_destination_arn
  flow_log_iam_role_arn    = var.flow_log_destination_type == "cloud-watch-logs" ? try(aws_iam_role.flowlogs_role[0].arn, null) : null
}

resource "aws_flow_log" "this" {
  iam_role_arn         = local.flow_log_iam_role_arn
  log_destination      = local.flow_log_destination_arn
  log_destination_type = var.flow_log_destination_type
  traffic_type         = "ALL"
  vpc_id               = local.vpc_id
}

resource "aws_cloudwatch_log_group" "this" {
  count = var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name              = "/aws/vpcflow/${local.vpc_id}"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id
  tags              = var.tags
}

resource "aws_iam_role" "flowlogs_role" {
  count = var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name = "${var.name}-flowlogs-cloudwatch-role"

  assume_role_policy = data.aws_iam_policy_document.flow_log_cloudwatch_assume_role[0].json
}

data "aws_iam_policy_document" "flow_log_cloudwatch_assume_role" {
  count = var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  statement {
    sid = "AWSVPCFlowLogsAssumeRole"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    effect = "Allow"

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "flowlogs_policy" {
  count = var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name        = "${var.name}-flowlogs-cloudwatch-policy"
  description = "Policy to allow vpc flow logs to forward logs to Cloudwatch"

  policy = data.aws_iam_policy_document.vpc_flow_log_cloudwatch[0].json
}

data "aws_iam_policy_document" "vpc_flow_log_cloudwatch" {
  count = var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0
  #checkov:skip=CKV_AWS_356: "Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-cwl.html
  statement {
    sid = "AWSVPCFlowLogsPushToCloudWatch"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}


resource "aws_iam_role_policy_attachment" "flowlogs_policy" {
  count = var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  role       = aws_iam_role.flowlogs_role[0].name
  policy_arn = aws_iam_policy.flowlogs_policy[0].arn
}
