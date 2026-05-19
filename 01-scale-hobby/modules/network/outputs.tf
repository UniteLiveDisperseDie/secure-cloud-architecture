# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# Subnets
output "public_subnet_id" {
  description = "Primary public subnet ID (EC2 + ASG 배치)"
  value       = aws_subnet.public_a.id
}

# Security Groups
output "sg_alb_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "sg_ec2_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.ec2.id
}

# ALB
output "alb_dns_name" {
  description = "ALB DNS name (dns 모듈 Route53 A 레코드에 사용)"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "ALB Hosted Zone ID (dns 모듈 Route53 alias에 사용)"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ALB ARN (observability 모듈에서 CloudWatch 메트릭 참조에 사용)"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.app.arn
}
