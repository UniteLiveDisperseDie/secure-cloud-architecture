output "ec2_instance_profile_name" {
  description = "EC2 모듈에 전달할 Instance Profile 이름"
  value       = aws_iam_instance_profile.app.name
}

output "ec2_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = aws_iam_role.ec2.arn
}

output "admin_role_arn" {
  description = "Admin 권한을 가진 Role ARN"
  value       = aws_iam_role.admin.arn
}

output "admin_boundary_arn" {
  description = "Admin role에 적용된 permission boundary ARN"
  value       = aws_iam_policy.admin_boundary.arn
}

output "user_group_name" {
  description = "기본 ReadOnly + AssumeRole 권한을 가진 IAM 그룹 이름"
  value       = aws_iam_group.users.name
}

output "user_arns" {
  value = { for k, u in aws_iam_user.this : k => u.arn }
}
