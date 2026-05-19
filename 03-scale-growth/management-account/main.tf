provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# ──────────────────────────────────────────
# Organizations / SCP
# OU 구조 생성 및 SCP 연결
# ──────────────────────────────────────────
module "organizations" {
  source = "./modules/organizations"

  project                = var.project
  management_account_id  = data.aws_caller_identity.current.account_id
  security_account_id    = var.security_account_id
  log_archive_account_id = var.log_archive_account_id
  production_account_id  = var.production_account_id
  staging_account_id     = var.staging_account_id
  development_account_id = var.development_account_id
  sandbox_account_id     = var.sandbox_account_id
  allowed_regions        = var.allowed_regions
}

# ──────────────────────────────────────────
# IAM Identity Center (SSO)
# Persona별 Permission Set / 그룹 / 계정 할당
# ──────────────────────────────────────────
module "identity_center" {
  source = "./modules/identity_center"

  project                = var.project
  management_account_id  = data.aws_caller_identity.current.account_id
  security_account_id    = var.security_account_id
  log_archive_account_id = var.log_archive_account_id
  production_account_id  = var.production_account_id
  staging_account_id     = var.staging_account_id
  development_account_id = var.development_account_id
  sandbox_account_id     = var.sandbox_account_id
}
