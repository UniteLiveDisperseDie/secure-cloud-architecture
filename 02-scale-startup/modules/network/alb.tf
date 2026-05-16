# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
  ]
  drop_invalid_header_fields = true

  access_logs {
    bucket  = var.alb_access_logs_bucket_name
    prefix  = "alb"
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-alb"
  })
}

# Target Group
resource "aws_lb_target_group" "app" {
  name        = "${var.project}-${var.environment}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-tg"
  })
}

# HTTPS Listener
# Default action: 403 for requests without the correct X-Origin-Secret header
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.alb_certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

# Listener Rule: forward only if X-Origin-Secret header matches
resource "aws_lb_listener_rule" "origin_secret" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100

  condition {
    http_header {
      http_header_name = "X-Origin-Secret"
      # ALB가 Secrets Manager를 직접 조회하지 않고,
      # 루트 모듈에서 생성한 동일한 secret 값을 입력으로 받아 검증한다.
      values = [var.cloudfront_shared_secret]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
