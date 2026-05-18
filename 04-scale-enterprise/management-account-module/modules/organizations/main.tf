data "aws_organizations_organization" "current" {}

locals {
  root_id = data.aws_organizations_organization.current.roots[0].id
}

# ─── Top-level OUs ───────────────────────────────────────────────────────────

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "infrastructure" {
  name      = "Infrastructure"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = local.root_id
}

# ─── Workloads 하위 OUs ───────────────────────────────────────────────────────

resource "aws_organizations_organizational_unit" "non_production" {
  name      = "Non-Production"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = aws_organizations_organizational_unit.workloads.id
}

# ─── Non-Production 하위 OUs ─────────────────────────────────────────────────

resource "aws_organizations_organizational_unit" "development" {
  name      = "Development"
  parent_id = aws_organizations_organizational_unit.non_production.id
}

resource "aws_organizations_organizational_unit" "staging" {
  name      = "Staging"
  parent_id = aws_organizations_organizational_unit.non_production.id
}

# ─── SCP 연결 ─────────────────────────────────────────────────────────────────

# Foundation SCP → Root (전 계정 공통)
resource "aws_organizations_policy_attachment" "foundation_root" {
  policy_id = aws_organizations_policy.foundation.id
  target_id = local.root_id
}

# Security OU SCP
resource "aws_organizations_policy_attachment" "security_ou" {
  policy_id = aws_organizations_policy.security_ou.id
  target_id = aws_organizations_organizational_unit.security.id
}

# Infrastructure OU SCP (공통)
resource "aws_organizations_policy_attachment" "infrastructure_ou" {
  policy_id = aws_organizations_policy.infrastructure_ou.id
  target_id = aws_organizations_organizational_unit.infrastructure.id
}

# Network 계정 전용 SCP (계정 레벨)
resource "aws_organizations_policy_attachment" "network_account" {
  policy_id = aws_organizations_policy.network_account.id
  target_id = var.network_account_id
}

# Backup 계정 전용 SCP (계정 레벨)
resource "aws_organizations_policy_attachment" "backup_account" {
  policy_id = aws_organizations_policy.backup_account.id
  target_id = var.backup_account_id
}

# Shared Services 계정 전용 SCP (계정 레벨)
resource "aws_organizations_policy_attachment" "shared_services_account" {
  policy_id = aws_organizations_policy.shared_services_account.id
  target_id = var.shared_services_account_id
}

# Production OU SCP
resource "aws_organizations_policy_attachment" "production_ou" {
  policy_id = aws_organizations_policy.production_ou.id
  target_id = aws_organizations_organizational_unit.production.id
}

# Staging OU SCP
resource "aws_organizations_policy_attachment" "staging_ou" {
  policy_id = aws_organizations_policy.staging_ou.id
  target_id = aws_organizations_organizational_unit.staging.id
}

# Development OU SCP
resource "aws_organizations_policy_attachment" "development_ou" {
  policy_id = aws_organizations_policy.development_ou.id
  target_id = aws_organizations_organizational_unit.development.id
}

# Sandbox OU SCP
resource "aws_organizations_policy_attachment" "sandbox_ou" {
  policy_id = aws_organizations_policy.sandbox_ou.id
  target_id = aws_organizations_organizational_unit.sandbox.id
}

# ─── 위임 관리자 지정 (Security Tooling 계정) ────────────────────────────────

resource "aws_guardduty_organization_admin_account" "security" {
  admin_account_id = var.security_tooling_account_id
}

resource "aws_inspector2_delegated_admin_account" "security" {
  account_id = var.security_tooling_account_id
  depends_on = [aws_guardduty_organization_admin_account.security]
}

resource "aws_organizations_delegated_administrator" "config" {
  account_id        = var.security_tooling_account_id
  service_principal = "config-multiaccountsetup.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "access_analyzer" {
  account_id        = var.security_tooling_account_id
  service_principal = "access-analyzer.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "securityhub" {
  account_id        = var.security_tooling_account_id
  service_principal = "securityhub.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "firewall_manager" {
  account_id        = var.security_tooling_account_id
  service_principal = "fms.amazonaws.com"
}
