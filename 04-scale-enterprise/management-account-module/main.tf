terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# ─── Organizations / OU 구조 + SCP ───────────────────────────────────────────
module "organizations" {
  source = "./modules/organizations"

  org_id                      = var.org_id
  allowed_regions             = var.allowed_regions
  log_archive_account_id      = var.log_archive_account_id
  audit_account_id            = var.audit_account_id
  security_tooling_account_id = var.security_tooling_account_id
  network_account_id          = var.network_account_id
  shared_services_account_id  = var.shared_services_account_id
  backup_account_id           = var.backup_account_id
  prod_app_account_id         = var.prod_app_account_id
  staging_app_account_id      = var.staging_app_account_id
  staging_data_account_id     = var.staging_data_account_id
  dev_team_account_id         = var.dev_team_account_id
  sandbox_account_id          = var.sandbox_account_id
}

# ─── IAM Identity Center / Persona별 Permission Set + 계정 할당 ───────────────
module "identity_center" {
  source = "./modules/identity_center"

  management_account_id       = data.aws_caller_identity.current.account_id
  log_archive_account_id      = var.log_archive_account_id
  audit_account_id            = var.audit_account_id
  security_tooling_account_id = var.security_tooling_account_id
  network_account_id          = var.network_account_id
  shared_services_account_id  = var.shared_services_account_id
  backup_account_id           = var.backup_account_id
  prod_app_account_id         = var.prod_app_account_id
  staging_app_account_id      = var.staging_app_account_id
  staging_data_account_id     = var.staging_data_account_id
  dev_team_account_id         = var.dev_team_account_id
  sandbox_account_id          = var.sandbox_account_id
}
