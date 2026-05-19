output "guardduty_detector_id" {
  value = var.enable_guardduty ? aws_guardduty_detector.this[0].id : ""
}
output "security_hub_arn" {
  value = var.enable_security_hub ? aws_securityhub_account.this[0].id : ""
}
output "remediation_lambda_arn" {
  value = var.enable_auto_remediation ? aws_lambda_function.auto_remediation[0].arn : ""
}
output "eventbridge_rule_arn" {
  value = var.enable_security_hub ? aws_cloudwatch_event_rule.findings[0].arn : ""
}
