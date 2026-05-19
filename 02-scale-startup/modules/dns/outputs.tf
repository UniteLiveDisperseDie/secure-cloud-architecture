output "acm_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (us-east-1, validated)"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "alb_certificate_arn" {
  description = "ACM certificate ARN for ALB (ap-northeast-2, validated)"
  value       = aws_acm_certificate_validation.alb.certificate_arn
}
