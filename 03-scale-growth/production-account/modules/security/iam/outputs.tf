output "ecs_task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "ecs_execution_role_arn" {
  value = aws_iam_role.ecs_execution.arn
}

output "ecs_instance_profile_name" {
  value = aws_iam_instance_profile.ecs.name
}

output "instance_role_arn" {
  value = aws_iam_role.ecs_instance.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
