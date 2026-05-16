output "ops_sns_topic_arn" {
  value = aws_sns_topic.ops_alerts.arn
}

output "cloudtrail_arn" {
  value = aws_cloudtrail.main.arn
}

output "cloudtrail_log_group_name" {
  value = aws_cloudwatch_log_group.cloudtrail.name
}
