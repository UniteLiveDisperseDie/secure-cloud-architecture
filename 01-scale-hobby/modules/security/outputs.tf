output "ec2_instance_profile_name" {
  description = "EC2 모듈에 전달할 Instance Profile 이름"
  value       = aws_iam_instance_profile.app.name
}

output "ec2_role_arn" {
  description = "EC2 IAM Role ARN"
  value       = aws_iam_role.ec2.arn
}

output "iam_user_arn" {
  description = "생성된 IAM User ARN"
  value       = aws_iam_user.this.arn
}
<<<<<<< HEAD
=======

output "github_actions_role_arn" {
  description = "GitHub Actions OIDC Role ARN (GitHub Secrets AWS_DEPLOY_ROLE_ARN에 등록)"
  value       = aws_iam_role.github_actions.arn
}
>>>>>>> cf1c8533f1a672c71ccb075097f0773ad5a265da
