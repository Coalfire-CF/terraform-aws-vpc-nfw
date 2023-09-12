######################
# VPC Endpoint for S3
######################
data "aws_vpc_endpoint_service" "s3" {
  count        = var.enable_s3_endpoint ? 1 : 0
  service_type = var.s3_endpoint_type
  service      = "s3"
}

resource "aws_vpc_endpoint" "s3" {
  count = var.enable_s3_endpoint ? 1 : 0

  vpc_id       = local.vpc_id
  service_name = data.aws_vpc_endpoint_service.s3[0].service_name
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count = var.enable_s3_endpoint ? local.nat_gateway_count : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = element(aws_route_table.private[*].id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "intra_s3" {
  count = var.enable_s3_endpoint && length(var.intra_subnets) > 0 ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = element(aws_route_table.intra[*].id, 0)
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  count = var.enable_s3_endpoint && length(var.public_subnets) > 0 ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
  route_table_id  = aws_route_table.public[0].id
}

############################
# VPC Endpoint for DynamoDB
############################
data "aws_vpc_endpoint_service" "dynamodb" {
  count        = var.enable_dynamodb_endpoint ? 1 : 0
  service_type = var.dynamodb_endpoint_type
  service      = "dynamodb"
}

resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id            = local.vpc_id
  vpc_endpoint_type = var.dynamodb_endpoint_type
  service_name      = data.aws_vpc_endpoint_service.dynamodb[0].service_name
}

resource "aws_vpc_endpoint_route_table_association" "private_dynamodb" {
  count = var.enable_dynamodb_endpoint ? local.nat_gateway_count : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = element(aws_route_table.private[*].id, count.index)
}

resource "aws_vpc_endpoint_route_table_association" "intra_dynamodb" {
  count = var.enable_dynamodb_endpoint && length(var.intra_subnets) > 0 ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = element(aws_route_table.intra[*].id, 0)
}

resource "aws_vpc_endpoint_route_table_association" "public_dynamodb" {
  count = var.enable_dynamodb_endpoint && length(var.public_subnets) > 0 ? 1 : 0

  vpc_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
  route_table_id  = aws_route_table.public[0].id
}
