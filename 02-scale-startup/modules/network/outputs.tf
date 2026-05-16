# VPC
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

# Subnets
output "public_subnet_ids" {
  description = "App tier public subnet IDs. public_b is intentionally excluded."
  value       = [aws_subnet.public_a.id]
}

output "alb_subnet_ids" {
  description = "Public subnet IDs used by the ALB (public_a and the empty public_b)"
  value = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
  ]
}

output "private_subnet_ids" {
  description = "Private subnet IDs (RDS)"
  value = [
    aws_subnet.private.id,
    aws_subnet.private_b.id,
  ]
}

# Security Groups
output "sg_alb_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "app_security_group_ids" {
  description = "EC2 security group IDs"
  value       = [aws_security_group.ec2.id]
}

output "db_security_group_ids" {
  description = "DB security group IDs"
  value       = [aws_security_group.db.id]
}

# ALB
output "alb_dns_name" {
  description = "ALB DNS name (used as CloudFront origin)"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "Target group ARN (for ASG attachment)"
  value       = aws_lb_target_group.app.arn
}
