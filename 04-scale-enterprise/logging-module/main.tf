##############################################################################
# Logging Module - Orchestration
##############################################################################

locals {
  name_prefix = "${var.project}-${var.environment}"

  # 기존 버킷 입력 여부에 따라 사용할 버킷 결정
  use_existing_bucket = var.existing_logging_bucket_id != ""
  bucket_id           = local.use_existing_bucket ? var.existing_logging_bucket_id : module.s3[0].bucket_id
  bucket_arn          = local.use_existing_bucket ? var.existing_logging_bucket_arn : module.s3[0].bucket_arn

  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "logging"
  })
}

# ── 0. Central Logging S3 (기존 버킷이 없을 때만 생성) ──────────────────────

module "s3" {
  source = "./modules/s3_logging"
  count  = local.use_existing_bucket ? 0 : 1

  name_prefix    = local.name_prefix
  retention_days = var.log_retention_days
  glacier_days   = var.log_glacier_days
  kms_key_arn    = var.kms_key_arn
  tags           = local.common_tags
}

# ── 1. Alerting (먼저 생성 — 다른 모듈이 SNS ARN을 참조) ───────────────────

module "alerting" {
  source = "./modules/alerting"

  name_prefix               = local.name_prefix
  slack_webhook_url         = var.slack_webhook_url
  slack_channel             = var.slack_channel
  jira_url                  = var.jira_url
  jira_api_token_secret_arn = var.jira_api_token_secret_arn
  jira_project_key          = var.jira_project_key
  jira_issue_type           = var.jira_issue_type
  tags                      = local.common_tags
}

# ── 2. Security Findings ────────────────────────────────────────────────────

module "security_findings" {
  source = "./modules/security_findings"

  name_prefix             = local.name_prefix
  logging_bucket_id       = local.bucket_id
  logging_bucket_arn      = local.bucket_arn
  sns_topic_arn           = module.alerting.sns_topic_arn
  enable_guardduty        = var.enable_guardduty
  enable_inspector        = var.enable_inspector
  enable_config           = var.enable_config
  enable_access_analyzer  = var.enable_access_analyzer
  enable_security_hub     = var.enable_security_hub
  enable_auto_remediation = var.enable_auto_remediation
  kms_key_arn             = var.kms_key_arn
  tags                    = local.common_tags
}

# ── 3. Log Sources ──────────────────────────────────────────────────────────

module "log_sources" {
  source = "./modules/log_sources"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  name_prefix        = local.name_prefix
  logging_bucket_id  = local.bucket_id
  logging_bucket_arn = local.bucket_arn
  waf_acl_arn        = var.waf_acl_arn
  vpc_ids            = var.vpc_ids
  alb_arns           = var.alb_arns
  route53_zone_ids   = var.route53_zone_ids
  tags               = local.common_tags
}

# ── 4. SaaS Integration ─────────────────────────────────────────────────────

module "saas_integration" {
  source = "./modules/saas_integration"

  name_prefix        = local.name_prefix
  logging_bucket_id  = local.bucket_id
  logging_bucket_arn = local.bucket_arn
  saas_apps          = var.saas_apps
  tags               = local.common_tags
}

# ── 5. On-Premise Integration ───────────────────────────────────────────────

module "onprem_integration" {
  source = "./modules/onprem_integration"

  name_prefix        = local.name_prefix
  logging_bucket_id  = local.bucket_id
  logging_bucket_arn = local.bucket_arn
  onprem_sources     = var.onprem_sources
  log_retention_days = var.cloudwatch_log_retention_days
  tags               = local.common_tags
}

# ── 6. OpenSearch SIEM (enable_opensearch = false면 생성 안 함) ─────────────

module "opensearch_siem" {
  source = "./modules/opensearch_siem"
  count  = var.enable_opensearch ? 1 : 0

  name_prefix        = local.name_prefix
  logging_bucket_id  = local.bucket_id
  logging_bucket_arn = local.bucket_arn
  instance_type      = var.opensearch_instance_type
  instance_count     = var.opensearch_instance_count
  ebs_volume_size    = var.opensearch_ebs_volume_size
  vpc_id             = var.opensearch_vpc_id
  subnet_ids         = var.opensearch_subnet_ids
  jira_lambda_arn    = module.alerting.jira_lambda_arn

  # 사용자 제공 자격증명/SG (비워두면 자동 생성)
  admin_secret_arn   = var.opensearch_admin_secret_arn
  security_group_ids = var.opensearch_security_group_ids
  log_retention_days = var.opensearch_log_retention_days

  tags = local.common_tags
}

# ── 7. Monitoring ───────────────────────────────────────────────────────────

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix          = local.name_prefix
  cloudtrail_log_group = module.log_sources.cloudtrail_log_group_name
  sns_topic_arn        = module.alerting.sns_topic_arn
  enable_amp           = var.enable_amp
  grafana_workspace_id = var.grafana_workspace_id
  tags                 = local.common_tags
}
