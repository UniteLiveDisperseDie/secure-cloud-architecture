# ──────────────────────────────────────────
# VPC Endpoints
# S3: Gateway 타입 (무료), 나머지: Interface 타입
# ECS Task가 인터넷 경유 없이 AWS 서비스에 접근
# ──────────────────────────────────────────

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_a.id,
    aws_route_table.private_b.id
  ]

  tags = { Name = "${var.project}-${var.environment}-s3-endpoint", Project = var.project, Environment = var.environment }
}

# ECR API Endpoint
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = { Name = "${var.project}-${var.environment}-ecr-api-endpoint", Project = var.project, Environment = var.environment }
}

# ECR DKR Endpoint (이미지 Pull)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = { Name = "${var.project}-${var.environment}-ecr-dkr-endpoint", Project = var.project, Environment = var.environment }
}

# SSM Endpoint (Session Manager)
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = { Name = "${var.project}-${var.environment}-ssm-endpoint", Project = var.project, Environment = var.environment }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = { Name = "${var.project}-${var.environment}-ssmmessages-endpoint", Project = var.project, Environment = var.environment }
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = { Name = "${var.project}-${var.environment}-ec2messages-endpoint", Project = var.project, Environment = var.environment }
}

# Secrets Manager Endpoint (ECS Task 런타임 조회)
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = { Name = "${var.project}-${var.environment}-secretsmanager-endpoint", Project = var.project, Environment = var.environment }
}

# CloudWatch Logs Endpoint (ECS 컨테이너 로그)
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = { Name = "${var.project}-${var.environment}-logs-endpoint", Project = var.project, Environment = var.environment }
}
