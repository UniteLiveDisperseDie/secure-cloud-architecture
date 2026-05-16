output "guardduty_detector_id" {
  value = module.guardduty.detector_id
}

output "security_sns_topic_arn" {
  value = aws_sns_topic.security_alerts.arn
}

output "access_analyzer_arn" {
  value = module.access_analyzer.analyzer_arn
}
