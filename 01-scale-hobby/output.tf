output "ec2_instance_profile_name" {
  description = "EC2 모듈에 전달할 Instance Profile 이름"
  value       = module.security.ec2_instance_profile_name
}

output "ec2_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = module.security.ec2_role_arn
}

output "iam_user_arn" {
  description = "생성된 IAM User ARN"
  value       = module.security.iam_user_arn
}

output "alarm_sns_topic_arn" {
  description = "알람 SNS Topic ARN"
  value       = module.observability.sns_topic_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "alb_dns_name" {
  description = "ALB DNS 이름"
  value       = module.network.alb_dns_name
}

output "ec2_instance_id" {
  description = "EC2 인스턴스 ID"
  value       = module.compute.ec2_instance_id
}

output "github_actions_role_arn" {
  description = "GitHub Actions OIDC Role ARN (GitHub Secrets AWS_DEPLOY_ROLE_ARN에 등록)"
  value       = module.security.github_actions_role_arn
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = module.waf.web_acl_arn
}
