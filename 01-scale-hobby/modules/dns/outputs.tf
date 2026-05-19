# ACM
output "acm_certificate_arn" {
  description = "ACM 인증서 ARN (networking 모듈 ALB Listener에 전달)"
  value       = aws_acm_certificate.alb.arn
}
