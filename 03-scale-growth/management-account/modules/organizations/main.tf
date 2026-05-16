# Organizations 데이터 소스 (Management Account에서 실행 전제)
data "aws_organizations_organization" "current" {}

# ──────────────────────────────────────────
# OU 구조 (3개 OU)
# ──────────────────────────────────────────
resource "aws_organizations_organizational_unit" "management" {
  name      = "Management"
  parent_id = data.aws_organizations_organization.current.roots[0].id
}

resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = data.aws_organizations_organization.current.roots[0].id
}

resource "aws_organizations_organizational_unit" "dev" {
  name      = "Dev"
  parent_id = data.aws_organizations_organization.current.roots[0].id
}

# ──────────────────────────────────────────
# SCP 연결
# ──────────────────────────────────────────
resource "aws_organizations_policy_attachment" "foundation_root" {
  policy_id = aws_organizations_policy.foundation.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}

resource "aws_organizations_policy_attachment" "management_ou" {
  policy_id = aws_organizations_policy.management_ou.id
  target_id = aws_organizations_organizational_unit.management.id
}

resource "aws_organizations_policy_attachment" "production_ou" {
  policy_id = aws_organizations_policy.production_ou.id
  target_id = aws_organizations_organizational_unit.production.id
}

resource "aws_organizations_policy_attachment" "dev_ou" {
  policy_id = aws_organizations_policy.dev_ou.id
  target_id = aws_organizations_organizational_unit.dev.id
}

# ──────────────────────────────────────────
# 위임 관리자 지정 (Security Account)
# Management Account에서 한 번만 실행
# ──────────────────────────────────────────
resource "aws_guardduty_organization_admin_account" "security" {
  admin_account_id = var.security_account_id
}

resource "aws_inspector2_delegated_admin_account" "security" {
  account_id = var.security_account_id
}

resource "aws_organizations_delegated_administrator" "config" {
  account_id        = var.security_account_id
  service_principal = "config-multiaccountsetup.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "access_analyzer" {
  account_id        = var.security_account_id
  service_principal = "access-analyzer.amazonaws.com"
}
