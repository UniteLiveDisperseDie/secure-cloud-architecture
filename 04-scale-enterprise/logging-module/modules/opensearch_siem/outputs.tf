output "endpoint" { value = aws_opensearch_domain.this.endpoint }
output "domain_arn" { value = aws_opensearch_domain.this.arn }
output "admin_secret_arn" { value = local.admin_secret_arn }
output "osis_pipeline_id" { value = aws_osis_pipeline.this.id }
output "security_group_ids" {
  description = "OpenSearch에 적용된 Security Group ID 목록 (자동 생성 또는 사용자 제공)"
  value       = local.security_group_ids
}
