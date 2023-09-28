resource "aws_kms_key" "nfw_key" {
  provider = aws.mgmt

  description         = "AWS Secrets Manager key for ${var.resource_prefix}"
  policy              = data.aws_iam_policy_document.nfw_kms_policy.json
  enable_key_rotation = true
}

resource "aws_kms_alias" "nfw_alias" {
  provider = aws.mgmt

  name          = "alias/${var.resource_prefix}-secrets-manager"
  target_key_id = aws_kms_key.nfw_key.key_id
}

data "aws_iam_policy_document" "nfw_kms_policy" {
  provider = aws.mgmt

  #checkov:skip=CKV_AWS_109: "Ensure IAM policies does not allow permissions management / resource exposure without constraints"
  #checkov:skip=CKV_AWS_111: "Ensure IAM policies does not allow write access without constraints"
  # https://docs.aws.amazon.com/network-firewall/latest/developerguide/kms-encryption-at-rest.html

  statement {
    sid     = "Enable IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
      type        = "AWS"
    }
    resources = ["*"]
  }
  statement {
    sid    = "Allow use of the key"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    principals {
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
      type        = "AWS"
    }
    resources = ["*"]
  }
  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    principals {
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
      type        = "AWS"
    }
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = [true]
    }
  }
}
