output "asg_name" {
  description = "Auto Scaling Group 이름"
  value       = aws_autoscaling_group.app_server.name
}

output "launch_template_id" {
  description = "Launch Template ID"
  value       = aws_launch_template.app_server.id
}

