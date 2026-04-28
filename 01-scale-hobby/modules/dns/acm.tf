# ACM 인증서 (ap-northeast-2 — ALB용)
resource "aws_acm_certificate" "alb" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-acm-alb"
  })
}

# DNS 검증 레코드 — 도메인 있을 때만 생성
resource "aws_route53_record" "acm_validation" {
  for_each = var.hosted_zone_id != "" ? {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  } : {}

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# ACM 검증 완료 대기 — 도메인 있을 때만
resource "aws_acm_certificate_validation" "alb" {
  count = var.hosted_zone_id != "" ? 1 : 0

  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for r in aws_route53_record.acm_validation : r.fqdn]
}
