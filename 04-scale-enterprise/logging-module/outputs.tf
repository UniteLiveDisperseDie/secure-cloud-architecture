output "logging_bucket_id" {
  description = "중앙 로깅 S3 버킷 이름"
  value       = local.bucket_id
}

output "logging_bucket_arn" {
  description = "중앙 로깅 S3 버킷 ARN"
  value       = local.bucket_arn
}

output "sns_topic_arn" {
  description = "Operational Alerts SNS Topic ARN. 추가 알람 연결 시 사용."
  value       = module.alerting.sns_topic_arn
}

output "opensearch_endpoint" {
  description = "OpenSearch 도메인 엔드포인트. enable_opensearch = false면 빈 문자열."
  value       = var.enable_opensearch ? module.opensearch_siem[0].endpoint : ""
}

output "opensearch_dashboard_url" {
  description = "OpenSearch Dashboards URL. VPN 또는 Bastion 경유 접속."
  value       = var.enable_opensearch ? "https://${module.opensearch_siem[0].endpoint}/_dashboards" : ""
}

output "opensearch_admin_secret_arn" {
  description = "OpenSearch admin 자격증명 Secrets Manager ARN. 초기 로그인 시 사용."
  value       = var.enable_opensearch ? module.opensearch_siem[0].admin_secret_arn : ""
}

output "guardduty_detector_id" {
  description = "GuardDuty Detector ID. Organizations Member 등록 시 사용."
  value       = var.enable_guardduty ? module.security_findings.guardduty_detector_id : ""
}

output "auto_remediation_lambda_arn" {
  description = "Auto Remediation Lambda ARN. 추가 EventBridge 연결 시 사용."
  value       = var.enable_auto_remediation ? module.security_findings.remediation_lambda_arn : ""
}

output "onprem_fluentbit_configs" {
  description = "온프레미스 소스별 FluentBit 연결 정보. Secrets Manager ARN에서 전체 설정 확인."
  sensitive   = true
  value       = module.onprem_integration.firehose_streams
}

output "amp_remote_write_url" {
  description = "Prometheus Remote Write URL. enable_amp = true 시 사용."
  value       = var.enable_amp ? module.monitoring.amp_remote_write_url : ""
}
