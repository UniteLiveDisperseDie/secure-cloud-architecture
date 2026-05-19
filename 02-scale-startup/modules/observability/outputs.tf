# Observability module outputs

output "s3_log_bucket_id" {
  description = "Name of the S3 bucket for log storage"
  value       = var.s3_log_bucket_name
}

output "s3_log_bucket_arn" {
  description = "ARN of the S3 bucket for log storage"
  value       = var.s3_log_bucket_arn
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = aws_cloudtrail.main.arn
}

output "cloudtrail_log_group_name" {
  description = "Name of the CloudWatch Log Group for CloudTrail"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "sns_alarm_topic_arn" {
  description = "ARN of the SNS topic for alarm notifications"
  value       = aws_sns_topic.alarm.arn
}
