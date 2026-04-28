# ALB Security Group
# 인터넷에서 HTTPS(443), HTTP(80) 수신
# HTTP(80)는 ALB Listener에서 HTTPS로 리다이렉트
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-sg-alb"
  description = "ALB: inbound HTTPS/HTTP from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from internet (redirect to HTTPS)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
# ALB SG 참조로만 앱 포트 허용, SSH(22) 제거 — SSM으로 대체
resource "aws_security_group" "ec2" {
  name        = "${var.project}-${var.environment}-sg-ec2"
  description = "EC2: inbound from ALB only, no SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "App port from ALB only"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound (SSM, S3, package updates, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-sg-ec2"
  })
}
