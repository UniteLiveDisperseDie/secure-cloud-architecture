# ═══════════════════════════════════════════════════════════════════════════════
# 계정 할당 (Persona 1 - 인프라 담당자)
# ═══════════════════════════════════════════════════════════════════════════════

# Security OU 3개 계정: ReadOnly
resource "aws_ssoadmin_account_assignment" "infra_log_archive" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.log_archive_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "infra_audit" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.audit_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "infra_security_tooling" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.security_tooling_account_id
  target_type        = "AWS_ACCOUNT"
}

# Infrastructure OU 3개 계정: AdministratorAccess
resource "aws_ssoadmin_account_assignment" "infra_network" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_admin.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.network_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "infra_shared_services" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_admin.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.shared_services_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "infra_backup" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_admin.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.backup_account_id
  target_type        = "AWS_ACCOUNT"
}

# Production / Staging: ReadOnly
resource "aws_ssoadmin_account_assignment" "infra_prod_app" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.prod_app_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "infra_staging_app" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.staging_app_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "infra_staging_data" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.staging_data_account_id
  target_type        = "AWS_ACCOUNT"
}

# Dev / Sandbox: AdministratorAccess
resource "aws_ssoadmin_account_assignment" "infra_dev_team" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_admin.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.dev_team_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "infra_sandbox" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_admin.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.sandbox_account_id
  target_type        = "AWS_ACCOUNT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 계정 할당 (Persona 2 - 보안 담당자)
# ═══════════════════════════════════════════════════════════════════════════════

resource "aws_ssoadmin_account_assignment" "security_management" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_readonly.arn
  principal_id       = aws_identitystore_group.security.group_id
  principal_type     = "GROUP"
  target_id          = var.management_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "security_log_archive" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_log_archive.arn
  principal_id       = aws_identitystore_group.security.group_id
  principal_type     = "GROUP"
  target_id          = var.log_archive_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "security_audit" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  principal_id       = aws_identitystore_group.security.group_id
  principal_type     = "GROUP"
  target_id          = var.audit_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "security_tooling_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_tooling_admin.arn
  principal_id       = aws_identitystore_group.security.group_id
  principal_type     = "GROUP"
  target_id          = var.security_tooling_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "security_network_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_readonly.arn
  principal_id       = aws_identitystore_group.security.group_id
  principal_type     = "GROUP"
  target_id          = var.network_account_id
  target_type        = "AWS_ACCOUNT"
}

# Production / Staging / Dev: SecurityAudit (AWS 관리형)
resource "aws_ssoadmin_account_assignment" "security_prod_audit" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  principal_id       = aws_identitystore_group.security.group_id
  principal_type     = "GROUP"
  target_id          = var.prod_app_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "security_staging_app_audit" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  principal_id       = aws_identitystore_group.security.group_id
  principal_type     = "GROUP"
  target_id          = var.staging_app_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "security_staging_data_audit" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  principal_id       = aws_identitystore_group.security.group_id
  principal_type     = "GROUP"
  target_id          = var.staging_data_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "security_dev_audit" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  principal_id       = aws_identitystore_group.security.group_id
  principal_type     = "GROUP"
  target_id          = var.dev_team_account_id
  target_type        = "AWS_ACCOUNT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 계정 할당 (Persona 3 - 백엔드/프론트엔드 개발자)
# ═══════════════════════════════════════════════════════════════════════════════

# Staging App: ReadOnly (배포 결과 확인 목적)
resource "aws_ssoadmin_account_assignment" "developer_staging_app" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_staging_readonly.arn
  principal_id       = aws_identitystore_group.developer.group_id
  principal_type     = "GROUP"
  target_id          = var.staging_app_account_id
  target_type        = "AWS_ACCOUNT"
}

# Dev Team: PowerUserAccess (IAM 제외)
resource "aws_ssoadmin_account_assignment" "developer_dev_team" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_power_user.arn
  principal_id       = aws_identitystore_group.developer.group_id
  principal_type     = "GROUP"
  target_id          = var.dev_team_account_id
  target_type        = "AWS_ACCOUNT"
}

# Dev Sandbox: AdministratorAccess
resource "aws_ssoadmin_account_assignment" "developer_sandbox" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_sandbox_admin.arn
  principal_id       = aws_identitystore_group.developer.group_id
  principal_type     = "GROUP"
  target_id          = var.sandbox_account_id
  target_type        = "AWS_ACCOUNT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 계정 할당 (Persona 4 - 데이터 엔지니어)
# ═══════════════════════════════════════════════════════════════════════════════

# Production App (데이터 영역): 제한적 ReadOnly
resource "aws_ssoadmin_account_assignment" "data_engineer_prod" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.data_engineer_prod.arn
  principal_id       = aws_identitystore_group.data_engineer.group_id
  principal_type     = "GROUP"
  target_id          = var.prod_app_account_id
  target_type        = "AWS_ACCOUNT"
}

# Staging Data: 커스텀 (S3/Redshift/MSK)
resource "aws_ssoadmin_account_assignment" "data_engineer_staging_data" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.data_engineer_staging.arn
  principal_id       = aws_identitystore_group.data_engineer.group_id
  principal_type     = "GROUP"
  target_id          = var.staging_data_account_id
  target_type        = "AWS_ACCOUNT"
}

# Dev Team: 데이터 서비스 전체 허용
resource "aws_ssoadmin_account_assignment" "data_engineer_dev" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.data_engineer_dev.arn
  principal_id       = aws_identitystore_group.data_engineer.group_id
  principal_type     = "GROUP"
  target_id          = var.dev_team_account_id
  target_type        = "AWS_ACCOUNT"
}

# Dev Sandbox: PowerUserAccess
resource "aws_ssoadmin_account_assignment" "data_engineer_sandbox" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.data_engineer_sandbox.arn
  principal_id       = aws_identitystore_group.data_engineer.group_id
  principal_type     = "GROUP"
  target_id          = var.sandbox_account_id
  target_type        = "AWS_ACCOUNT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 계정 할당 (Persona 5 - SRE / On-call)
# ═══════════════════════════════════════════════════════════════════════════════

resource "aws_ssoadmin_account_assignment" "sre_security_tooling" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.sre_access.arn
  principal_id       = aws_identitystore_group.sre.group_id
  principal_type     = "GROUP"
  target_id          = var.security_tooling_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "sre_network" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.sre_access.arn
  principal_id       = aws_identitystore_group.sre.group_id
  principal_type     = "GROUP"
  target_id          = var.network_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "sre_prod_app" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.sre_access.arn
  principal_id       = aws_identitystore_group.sre.group_id
  principal_type     = "GROUP"
  target_id          = var.prod_app_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "sre_staging_app" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.sre_access.arn
  principal_id       = aws_identitystore_group.sre.group_id
  principal_type     = "GROUP"
  target_id          = var.staging_app_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "sre_dev_team" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.sre_access.arn
  principal_id       = aws_identitystore_group.sre.group_id
  principal_type     = "GROUP"
  target_id          = var.dev_team_account_id
  target_type        = "AWS_ACCOUNT"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 계정 할당 (Persona 6 - Auditor)
# ═══════════════════════════════════════════════════════════════════════════════

locals {
  auditor_accounts = {
    management      = var.management_account_id
    log_archive     = var.log_archive_account_id
    audit           = var.audit_account_id
    network         = var.network_account_id
    shared_services = var.shared_services_account_id
    backup          = var.backup_account_id
    prod_app        = var.prod_app_account_id
    staging_app     = var.staging_app_account_id
    staging_data    = var.staging_data_account_id
    dev_team        = var.dev_team_account_id
  }
}

resource "aws_ssoadmin_account_assignment" "auditor" {
  for_each = local.auditor_accounts

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.auditor_access.arn
  principal_id       = aws_identitystore_group.auditor.group_id
  principal_type     = "GROUP"
  target_id          = each.value
  target_type        = "AWS_ACCOUNT"
}
