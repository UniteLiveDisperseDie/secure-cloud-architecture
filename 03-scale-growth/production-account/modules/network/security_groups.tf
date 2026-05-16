data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ──────────────────────────────────────────
# ALB SG
# ──────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "ALB: CloudFront IP대역에서만 HTTPS/HTTP 수신"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project}-${var.environment}-alb-sg", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from CloudFront"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from CloudFront (HTTPS redirect)"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
}

resource "aws_security_group_rule" "alb_egress_ecs" {
  type                     = "egress"
  security_group_id        = aws_security_group.alb.id
  description              = "ALB to ECS"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

# ──────────────────────────────────────────
# ECS SG
# ──────────────────────────────────────────
resource "aws_security_group" "ecs" {
  name        = "${var.project}-${var.environment}-ecs-sg"
  description = "ECS Task: ALB에서만 8080 수신, DB/Cache 접근"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project}-${var.environment}-ecs-sg", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_security_group_rule" "ecs_ingress_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ecs.id
  description              = "App port from ALB"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "ecs_egress_https" {
  type              = "egress"
  security_group_id = aws_security_group.ecs.id
  description       = "HTTPS outbound (ECR/Secrets Manager)"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ecs_egress_rds" {
  type                     = "egress"
  security_group_id        = aws_security_group.ecs.id
  description              = "MySQL to RDS"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
}

resource "aws_security_group_rule" "ecs_egress_redis" {
  type                     = "egress"
  security_group_id        = aws_security_group.ecs.id
  description              = "Redis to ElastiCache"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cache.id
}

# ──────────────────────────────────────────
# DB SG
# ──────────────────────────────────────────
resource "aws_security_group" "db" {
  name        = "${var.project}-${var.environment}-db-sg"
  description = "RDS: ECS SG에서만 MySQL 3306 수신"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project}-${var.environment}-db-sg", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_security_group_rule" "db_ingress_ecs" {
  type                     = "ingress"
  security_group_id        = aws_security_group.db.id
  description              = "MySQL from ECS"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

# ──────────────────────────────────────────
# Cache SG
# ──────────────────────────────────────────
resource "aws_security_group" "cache" {
  name        = "${var.project}-${var.environment}-cache-sg"
  description = "ElastiCache: ECS SG에서만 Redis 6379 수신"
  vpc_id      = aws_vpc.main.id

  tags = { Name = "${var.project}-${var.environment}-cache-sg", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_security_group_rule" "cache_ingress_ecs" {
  type                     = "ingress"
  security_group_id        = aws_security_group.cache.id
  description              = "Redis from ECS"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ecs.id
}

# ──────────────────────────────────────────
# VPC Endpoint SG
# ──────────────────────────────────────────
resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.project}-${var.environment}-vpce-sg"
  description = "VPC Endpoint: ECS/EC2에서 HTTPS 443 수신"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = { Name = "${var.project}-${var.environment}-vpce-sg", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}
