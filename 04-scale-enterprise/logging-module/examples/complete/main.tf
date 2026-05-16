##############################################################################
# 사용 예시 — 이 파일을 복사해 자신의 인프라 레포에 붙여넣으세요.
##############################################################################

provider "aws" {
  region = "ap-northeast-2"
}

# Route53 DNS 쿼리 로그는 us-east-1 CloudWatch 필수
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "logging" {
  source = "github.com/yourorg/terraform-modules//logging"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  # ── 필수 ──────────────────────────────────────────────────────────────────
  project     = "mycompany"
  environment = "prod"

  # ── AWS 인프라 연결 ────────────────────────────────────────────────────────
  vpc_ids          = ["vpc-0a1b2c3d4e5f67890"]
  waf_acl_arn      = "arn:aws:wafv2:ap-northeast-2:123456789012:regional/webacl/prod-waf/xxxx"
  alb_arns         = ["arn:aws:elasticloadbalancing:ap-northeast-2:123456789012:loadbalancer/app/prod/xxxx"]
  route53_zone_ids = ["Z1D633PJN98FT9"]

  # ── SaaS 연결 (항목 추가만 하면 됩니다) ───────────────────────────────────
  saas_apps = [
    {
      name                  = "github"
      app_type              = "GITHUB"
      credential_secret_arn = "arn:aws:secretsmanager:ap-northeast-2:123456789012:secret:logging/github-oauth"
    },
    {
      name                  = "confluence"
      app_type              = "ATLASSIAN"
      credential_secret_arn = "arn:aws:secretsmanager:ap-northeast-2:123456789012:secret:logging/atlassian-oauth"
      tenant_id             = "mycompany.atlassian.net"
    },
    {
      name                  = "google-workspace"
      app_type              = "GOOGLEWORKSPACE"
      credential_secret_arn = "arn:aws:secretsmanager:ap-northeast-2:123456789012:secret:logging/gws-oauth"
      tenant_id             = "mycompany.com"
    },
  ]

  # ── 온프레미스 연결 (항목 추가만 하면 됩니다) ───────────────────────────────
  onprem_sources = [
    {
      name        = "idc-primary"
      description = "주 IDC"
      log_prefix  = "onprem/idc-primary/"
    },
    {
      name        = "idc-dr"
      description = "DR IDC"
      log_prefix  = "onprem/idc-dr/"
    },
  ]

  # ── OpenSearch ─────────────────────────────────────────────────────────────
  opensearch_vpc_id          = "vpc-0a1b2c3d4e5f67890"
  opensearch_subnet_ids      = ["subnet-0aaa1111", "subnet-0bbb2222"]
  opensearch_instance_type   = "r6g.large.search"
  opensearch_instance_count  = 2
  opensearch_ebs_volume_size = 200

  # ── Alerting ───────────────────────────────────────────────────────────────
  slack_webhook_url         = "https://hooks.slack.com/services/T.../B.../xxx"
  slack_channel             = "#security-alerts"
  jira_url                  = "https://mycompany.atlassian.net"
  jira_api_token_secret_arn = "arn:aws:secretsmanager:ap-northeast-2:123456789012:secret:logging/jira-token"
  jira_project_key          = "SEC"

  tags = {
    Team       = "platform-security"
    CostCenter = "sec-001"
  }
}

# ── Outputs ───────────────────────────────────────────────────────────────────

output "logging_bucket" { value = module.logging.logging_bucket_id }
output "opensearch_dashboard" { value = module.logging.opensearch_dashboard_url }
output "sns_topic_arn" { value = module.logging.sns_topic_arn }
output "onprem_fluentbit_guide" {
  value     = <<-EOT
    온프레미스 FluentBit 설정 방법:
    1. Secrets Manager에서 자격증명 확인:
       aws secretsmanager get-secret-value \\
         --secret-id <credentials_secret_arn>
    2. fluentbit_output_config 값을 /etc/fluent-bit/fluent-bit.conf에 적용
    3. FluentBit 재시작
  EOT
  sensitive = false
}
