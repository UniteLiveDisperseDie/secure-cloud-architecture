provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# ──────────────────────────────────────────
# KMS CMK (s3-log-cmk)
# CloudTrail, Config, VPC Flow Logs, ALB 로그 암호화 전용 키
# ──────────────────────────────────────────
module "kms" {
  source = "./modules/kms"

  project                = var.project
  region                 = var.region
  management_account_id  = var.management_account_id
  security_account_id    = var.security_account_id
  production_account_id  = var.production_account_id
  staging_account_id     = var.staging_account_id
  development_account_id = var.development_account_id
  log_archive_account_id = data.aws_caller_identity.current.account_id
}

# ──────────────────────────────────────────
# S3 중앙 로그 버킷
# Object Lock(COMPLIANCE), 버저닝, SSE-KMS, lifecycle 계층화
# ──────────────────────────────────────────
module "s3" {
  source = "./modules/s3"

  project                = var.project
  region                 = var.region
  log_bucket_name        = var.log_bucket_name
  log_archive_account_id = data.aws_caller_identity.current.account_id
  management_account_id  = var.management_account_id
  production_account_id  = var.production_account_id
  staging_account_id     = var.staging_account_id
  development_account_id = var.development_account_id
  security_account_id    = var.security_account_id
  kms_key_arn            = module.kms.s3_log_key_arn

  depends_on = [module.kms]
}
