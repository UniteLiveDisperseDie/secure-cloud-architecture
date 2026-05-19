provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# ──────────────────────────────────────────
# SNS - 보안 알림
# ──────────────────────────────────────────
resource "aws_sns_topic" "security_alerts" {
  name = "${var.project}-security-alerts"

  tags = {
    Name      = "${var.project}-security-alerts"
    Project   = var.project
    ManagedBy = "terraform"
  }
}

resource "aws_sns_topic_subscription" "security_email" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ──────────────────────────────────────────
# GuardDuty
# ──────────────────────────────────────────
module "guardduty" {
  source = "./modules/guardduty"

  project             = var.project
  region              = var.region
  sns_topic_arn       = aws_sns_topic.security_alerts.arn
  organization_id     = var.organization_id
}

# ──────────────────────────────────────────
# Inspector
# ──────────────────────────────────────────
module "inspector" {
  source = "./modules/inspector"

  project = var.project
}

# ──────────────────────────────────────────
# AWS Config 집계 (Organization)
# ──────────────────────────────────────────
module "config_aggregator" {
  source = "./modules/config_aggregator"

  project         = var.project
  organization_id = var.organization_id
}

# ──────────────────────────────────────────
# IAM Access Analyzer (Organization 범위)
# ──────────────────────────────────────────
module "access_analyzer" {
  source = "./modules/access_analyzer"

  project       = var.project
  sns_topic_arn = aws_sns_topic.security_alerts.arn
}
