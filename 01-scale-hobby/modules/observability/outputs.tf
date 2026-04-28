output "sns_topic_arn" {
  description = "알람 SNS Topic ARN"
  value       = aws_sns_topic.alarm.arn
}
