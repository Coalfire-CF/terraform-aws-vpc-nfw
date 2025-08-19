locals {
  partition           = data.aws_partition.current.partition
  prod_app_account_id = var.account_number
}

