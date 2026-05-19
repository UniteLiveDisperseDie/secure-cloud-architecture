# S3 Gateway Endpoint
# Routes EC2 → S3 traffic through the AWS internal network (no NAT, no internet)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id]

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-vpce-s3"
  })
}

data "aws_region" "current" {}
