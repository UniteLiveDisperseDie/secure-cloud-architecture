# ACM Certificate
# CloudFront must use certificates created specifically in the us-east-1 region.

# us-east-1 provider alias
# An alias provider must be declared in environments/prod(or dev)/main.tf
# 이 스택은 apex 도메인과 wildcard 도메인만 함께 인증한다.
# ACM은 이 조합에 대해 같은 DNS validation CNAME을 반환하므로
# apex 도메인 기준 레코드 하나만 생성해 재사용한다.
locals {
  acm_validation_by_domain = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
}

# ACM Certificate Issuance (us-east-1)
# Wildcard certificate: covers both *.example.com and example.com simultaneously
resource "aws_acm_certificate" "main" {
  provider = aws.us_east_1

  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  # Ensure the new certificate is created before the existing one is deleted during replacement
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-acm"
  })
}

# Automatically create DNS validation records in Route 53
resource "aws_route53_record" "acm_validation" {
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = local.acm_validation_by_domain[var.domain_name].name
  type            = local.acm_validation_by_domain[var.domain_name].type
  records         = [local.acm_validation_by_domain[var.domain_name].record]
  ttl             = 60
  allow_overwrite = true
}

# Wait for DNS validation to complete
resource "aws_acm_certificate_validation" "main" {
  provider = aws.us_east_1

  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [aws_route53_record.acm_validation.fqdn]
}

# ACM Certificate for ALB (ap-northeast-2)
# CloudFront requires us-east-1; ALB requires the region where it is deployed
resource "aws_acm_certificate" "alb" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-alb-acm"
  })
}

# Reuse the same DNS validation records created for the CloudFront certificate
resource "aws_acm_certificate_validation" "alb" {
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [aws_route53_record.acm_validation.fqdn]
}
