output "sso_instance_arn" {
  description = "IAM Identity Center instance ARN"
  value       = local.sso_instance_arn
}

output "identity_store_id" {
  description = "IAM Identity Center identity store ID"
  value       = local.identity_store_id
}

output "group_ids" {
  description = "IAM Identity Center 그룹 ID 맵"
  value = {
    infra        = aws_identitystore_group.infra.group_id
    security     = aws_identitystore_group.security.group_id
    developer    = aws_identitystore_group.developer.group_id
    data_engineer = aws_identitystore_group.data_engineer.group_id
    sre          = aws_identitystore_group.sre.group_id
    auditor      = aws_identitystore_group.auditor.group_id
  }
}

output "permission_set_arns" {
  description = "Permission Set ARN 맵"
  value = {
    infra_admin              = aws_ssoadmin_permission_set.infra_admin.arn
    infra_readonly           = aws_ssoadmin_permission_set.infra_readonly.arn
    security_tooling_admin   = aws_ssoadmin_permission_set.security_tooling_admin.arn
    security_log_archive     = aws_ssoadmin_permission_set.security_log_archive.arn
    security_readonly        = aws_ssoadmin_permission_set.security_readonly.arn
    security_audit           = aws_ssoadmin_permission_set.security_audit.arn
    developer_power_user     = aws_ssoadmin_permission_set.developer_power_user.arn
    developer_sandbox_admin  = aws_ssoadmin_permission_set.developer_sandbox_admin.arn
    developer_staging_readonly = aws_ssoadmin_permission_set.developer_staging_readonly.arn
    data_engineer_prod       = aws_ssoadmin_permission_set.data_engineer_prod.arn
    data_engineer_staging    = aws_ssoadmin_permission_set.data_engineer_staging.arn
    data_engineer_dev        = aws_ssoadmin_permission_set.data_engineer_dev.arn
    data_engineer_sandbox    = aws_ssoadmin_permission_set.data_engineer_sandbox.arn
    sre_access               = aws_ssoadmin_permission_set.sre_access.arn
    auditor_access           = aws_ssoadmin_permission_set.auditor_access.arn
  }
}
