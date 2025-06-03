locals {
  flow_log_destination_arn = var.flow_log_destination_type == "cloud-watch-logs" ? try(aws_cloudwatch_log_group.this[0].arn, null) : var.flow_log_destination_arn
  flow_log_iam_role_arn    = var.flow_log_destination_type == "cloud-watch-logs" ? try(aws_iam_role.flowlogs_role[0].arn, null) : null
}

data "aws_region" "current" {}


resource "aws_flow_log" "this" {
  count = var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0
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




resource "aws_flow_log" "s3" {
  count = var.flow_log_destination_type == "s3" ? 1 : 0
  iam_role_arn         = local.flow_log_iam_role_arn
  log_destination_type = var.flow_log_destination_type
  traffic_type         = "ALL"
  vpc_id               = local.vpc_id
}

resource "aws_s3_bucket" "flowlogs" {
  count = var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = "${var.name}-${data.aws_region.current.name}-vpcflowlogs"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flowlogs-encryption" {
  count = var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.flowlogs[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.s3_kms_key_arn
    }
  }
}

data "aws_iam_policy_document" "flowlogs_policy" {
  statement {
    actions = ["s3:GetBucketAcl"]
    effect  = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    resources = [aws_s3_bucket.flowlogs[0].arn]
  }

  statement {
    actions = ["s3:PutObject"]
    effect  = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    resources = [
    "${aws_s3_bucket.flowlogs[0].arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    actions = ["s3:GetObject", "s3:ListBucket"]
    effect  = "Allow"
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
    resources = ["${aws_s3_bucket.flowlogs[0].arn}/*",
    aws_s3_bucket.flowlogs[0].arn]
  }
}

resource "aws_s3_bucket_policy" "flowlogs_bucket_policy" {
  count = var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.flowlogs[0].bucket
  policy = data.aws_iam_policy_document.flowlogs_policy.json
}

resource "aws_s3_bucket_public_access_block" "flowlogs" {
  count = var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.flowlogs[0].id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}
resource "aws_s3_bucket_logging" "flowlogs" {
  count = var.flow_log_destination_type == "s3" ? 1 : 0
  bucket = aws_s3_bucket.flowlogs[0].id

  target_bucket = var.s3_access_logs_bucket
  target_prefix = "flowlogs/"
}