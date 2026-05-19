# CloudFront managed prefix list (global)
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ALB Security Group
# Allows inbound HTTPS only from CloudFront origin-facing IPs
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-sg-alb"
  description = "ALB: inbound HTTPS from CloudFront only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTPS from CloudFront"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-sg-alb"
  })
}

# EC2 Security Group
# Allows inbound from ALB only; outbound unrestricted (S3, SSM, etc.)
resource "aws_security_group" "ec2" {
  name        = "${var.project}-${var.environment}-sg-ec2"
  description = "EC2: inbound from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App port from ALB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound(SSM, S3, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-sg-ec2"
  })
}

# DB Security Group
# Allows inbound from EC2 only; no outbound needed
resource "aws_security_group" "db" {
  name        = "${var.project}-${var.environment}-sg-db"
  description = "RDS: inbound from EC2 only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "DB port from EC2"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-sg-db"
  })
}
