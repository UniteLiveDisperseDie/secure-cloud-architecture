data "aws_ssoadmin_instances" "main" {}

locals {
  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}

# ──────────────────────────────────────────
# Permission Sets (Persona별)
# ──────────────────────────────────────────

# Persona 1 - 인프라 담당자: Production/Security/LogArchive ReadOnly
resource "aws_ssoadmin_permission_set" "infra_readonly" {
  name             = "InfraReadOnly"
  description      = "인프라 담당자: Production/Security/LogArchive ReadOnly"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "infra_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Persona 1 - 인프라 담당자: Dev/Sandbox AdministratorAccess
resource "aws_ssoadmin_permission_set" "infra_admin" {
  name             = "InfraAdmin"
  description      = "인프라 담당자: Dev/Sandbox AdministratorAccess"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "infra_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Persona 2 - 보안 담당자: Security Account Admin (MFA 필수, 4시간)
resource "aws_ssoadmin_permission_set" "security_admin" {
  name             = "SecurityAdmin"
  description      = "보안 담당자: Security Account Admin (MFA 필수)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "security_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# MFA 없이 접근 차단 인라인 정책
resource "aws_ssoadmin_permission_set_inline_policy" "security_admin_mfa" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_admin.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DenyWithoutMFA"
      Effect = "Deny"
      NotAction = [
        "iam:CreateVirtualMFADevice",
        "iam:EnableMFADevice",
        "iam:GetUser",
        "iam:ListMFADevices",
        "iam:ListVirtualMFADevices",
        "iam:ResyncMFADevice",
        "sts:GetSessionToken"
      ]
      Resource = "*"
      Condition = {
        BoolIfExists = {
          "aws:MultiFactorAuthPresent" = "false"
        }
      }
    }]
  })
}

# Persona 2 - 보안 담당자: 타 계정 SecurityAudit
resource "aws_ssoadmin_permission_set" "security_audit" {
  name             = "SecurityAudit"
  description      = "보안 담당자: Production/Staging/Dev SecurityAudit"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "security_audit" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# Persona 3 - 개발자: Production/Staging ReadOnly
resource "aws_ssoadmin_permission_set" "developer_readonly" {
  name             = "DeveloperReadOnly"
  description      = "개발자: Production/Staging ReadOnly"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "developer_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Persona 3 - 개발자: Development PowerUserAccess
resource "aws_ssoadmin_permission_set" "developer_power_user" {
  name             = "DeveloperPowerUser"
  description      = "개발자: Development PowerUserAccess (IAM 제외)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "developer_power_user" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_power_user.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Persona 5 - 경영진: Billing ReadOnly
resource "aws_ssoadmin_permission_set" "billing_readonly" {
  name             = "BillingReadOnly"
  description      = "경영진: Management Account Billing ReadOnly"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "billing_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.billing_readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
}

# ──────────────────────────────────────────
# 그룹 정의
# ──────────────────────────────────────────
resource "aws_identitystore_group" "infra" {
  identity_store_id = local.identity_store_id
  display_name      = "infra-team"
  description       = "인프라/DevOps 담당자 그룹"
}

resource "aws_identitystore_group" "security" {
  identity_store_id = local.identity_store_id
  display_name      = "security-team"
  description       = "보안 담당자 그룹"
}

resource "aws_identitystore_group" "developer" {
  identity_store_id = local.identity_store_id
  display_name      = "developer-team"
  description       = "백엔드/프론트엔드 개발자 그룹"
}

resource "aws_identitystore_group" "executive" {
  identity_store_id = local.identity_store_id
  display_name      = "executive-team"
  description       = "경영진 그룹"
}

# ──────────────────────────────────────────
# 계정 할당 (Persona 1: 인프라 담당자)
# ──────────────────────────────────────────
resource "aws_ssoadmin_account_assignment" "infra_production_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.production_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "infra_security_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.security_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "infra_logarchive_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.log_archive_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "infra_staging_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.staging_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "infra_development_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_admin.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.development_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "infra_sandbox_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_admin.arn
  principal_id       = aws_identitystore_group.infra.group_id
  principal_type     = "GROUP"
  target_id          = var.sandbox_account_id
  target_type        = "AWS_ACCOUNT"
}

# ──────────────────────────────────────────
# 계정 할당 (Persona 2: 보안 담당자)
# ──────────────────────────────────────────
resource "aws_ssoadmin_account_assignment" "security_security_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_admin.arn
  principal_id       = aws_identitystore_group.security.group_id
  principal_type     = "GROUP"
  target_id          = var.security_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "security_logarchive_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  principal_id       = aws_identitystore_group.security.group_id
  principal_type     = "GROUP"
  target_id          = var.log_archive_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "security_workload_audit" {
  for_each = toset([
    var.production_account_id,
    var.staging_account_id,
    var.development_account_id
  ])

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  principal_id       = aws_identitystore_group.security.group_id
  principal_type     = "GROUP"
  target_id          = each.value
  target_type        = "AWS_ACCOUNT"
}

# ──────────────────────────────────────────
# 계정 할당 (Persona 3: 개발자)
# ──────────────────────────────────────────
resource "aws_ssoadmin_account_assignment" "developer_production_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_readonly.arn
  principal_id       = aws_identitystore_group.developer.group_id
  principal_type     = "GROUP"
  target_id          = var.production_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "developer_staging_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_readonly.arn
  principal_id       = aws_identitystore_group.developer.group_id
  principal_type     = "GROUP"
  target_id          = var.staging_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "developer_development_power_user" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_power_user.arn
  principal_id       = aws_identitystore_group.developer.group_id
  principal_type     = "GROUP"
  target_id          = var.development_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "developer_sandbox_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_admin.arn
  principal_id       = aws_identitystore_group.developer.group_id
  principal_type     = "GROUP"
  target_id          = var.sandbox_account_id
  target_type        = "AWS_ACCOUNT"
}

# ──────────────────────────────────────────
# 계정 할당 (Persona 5: 경영진)
# ──────────────────────────────────────────
resource "aws_ssoadmin_account_assignment" "executive_billing" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.billing_readonly.arn
  principal_id       = aws_identitystore_group.executive.group_id
  principal_type     = "GROUP"
  target_id          = var.management_account_id
  target_type        = "AWS_ACCOUNT"
}
