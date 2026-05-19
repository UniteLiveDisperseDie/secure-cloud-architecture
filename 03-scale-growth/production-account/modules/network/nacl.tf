# ──────────────────────────────────────────
# NACL 1: 퍼블릭 서브넷 (ALB 위치)
# NACL은 Stateless이므로 Ephemeral Port가 반드시 필요
# ──────────────────────────────────────────
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  # 인바운드
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  # Ephemeral Port (HTTP 응답 트래픽)
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # 아웃바운드
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_cidr_a
    from_port  = 8080
    to_port    = 8080
  }

  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_cidr_b
    from_port  = 8080
    to_port    = 8080
  }

  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = { Name = "${var.project}-${var.environment}-public-nacl", Project = var.project, Environment = var.environment }
}

# ──────────────────────────────────────────
# NACL 2: 프라이빗 서브넷 (ECS 위치)
# ──────────────────────────────────────────
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  # 인바운드: ALB에서만 인입
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_subnet_cidr_a
    from_port  = 8080
    to_port    = 8080
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_subnet_cidr_b
    from_port  = 8080
    to_port    = 8080
  }

  # 외부 통신 응답 (NAT GW를 통한 외부 API 혹답)
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  # 아웃바운드: HTTPS 외부 API (ECR·S3·SSM은 VPC Endpoint 경유)
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # ECS → RDS
  egress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.db_subnet_cidr_a
    from_port  = 3306
    to_port    = 3306
  }

  egress {
    rule_no    = 111
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.db_subnet_cidr_b
    from_port  = 3306
    to_port    = 3306
  }

  # ECS → ElastiCache
  egress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.db_subnet_cidr_a
    from_port  = 6379
    to_port    = 6379
  }

  egress {
    rule_no    = 121
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.db_subnet_cidr_b
    from_port  = 6379
    to_port    = 6379
  }

  # ALB 요청 응답 트래픽 반환
  egress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_subnet_cidr_a
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 131
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.public_subnet_cidr_b
    from_port  = 1024
    to_port    = 65535
  }

  tags = { Name = "${var.project}-${var.environment}-private-nacl", Project = var.project, Environment = var.environment }
}

# ──────────────────────────────────────────
# NACL 3: DB 서브넷 (RDS + ElastiCache 위치)
# ──────────────────────────────────────────
resource "aws_network_acl" "db" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.db_a.id, aws_subnet.db_b.id]

  # 인바운드: ECS 서브넷에서만 RDS/ElastiCache 허용
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_cidr_a
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    rule_no    = 101
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_cidr_b
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_cidr_a
    from_port  = 6379
    to_port    = 6379
  }

  ingress {
    rule_no    = 111
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_cidr_b
    from_port  = 6379
    to_port    = 6379
  }

  # 아웃바운드: 응답 트래픽만 ECS 서브넷으로 (DB에서 외부 통신 없음)
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_cidr_a
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 101
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.private_subnet_cidr_b
    from_port  = 1024
    to_port    = 65535
  }

  tags = { Name = "${var.project}-${var.environment}-db-nacl", Project = var.project, Environment = var.environment }
}
