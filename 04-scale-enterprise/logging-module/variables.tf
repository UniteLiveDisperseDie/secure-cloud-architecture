##############################################################################
# Logging Module - Variables
##############################################################################

# ── 필수 ─────────────────────────────────────────────────────────────────────

variable "project" {
  description = "리소스 이름 prefix. 소문자와 하이픈만 사용. 예: mycompany"
  type        = string
}

variable "environment" {
  description = "배포 환경. dev | stg | prod"
  type        = string
}

variable "opensearch_vpc_id" {
  description = "OpenSearch 도메인을 배치할 VPC ID. 기존 VPC를 입력하세요."
  type        = string
}

variable "opensearch_subnet_ids" {
  description = "OpenSearch 서브넷 ID 목록. Private Subnet 2개 이상 권장."
  type        = list(string)
}

# ── 기존 인프라 재사용 ────────────────────────────────────────────────────────
# 이미 있는 리소스는 ARN/ID를 입력하면 새로 만들지 않습니다.

variable "existing_logging_bucket_id" {
  description = "기존 S3 버킷을 로깅 저장소로 사용할 경우 버킷 이름 입력. 비우면 신규 생성."
  type        = string
  default     = ""
}

variable "existing_logging_bucket_arn" {
  description = "existing_logging_bucket_id와 함께 입력."
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "S3 암호화용 기존 KMS Key ARN. null이면 SSE-S3 자동 적용."
  type        = string
  default     = null
}

# ── 기존 인프라 연결 — 해당 항목이 있으면 입력, 없으면 생략 ───────────────────

variable "vpc_ids" {
  description = "VPC Flow Log를 활성화할 기존 VPC ID 목록. 빈 리스트면 Flow Log 생성 안 함."
  type        = list(string)
  default     = []
}

variable "waf_acl_arn" {
  description = "WAF 로그를 수집할 기존 WebACL ARN. 비우면 WAF 로깅 생성 안 함."
  type        = string
  default     = ""
}

variable "alb_arns" {
  description = "Access Log를 활성화할 기존 ALB ARN 목록."
  type        = list(string)
  default     = []
}

variable "route53_zone_ids" {
  description = "DNS Query Logging을 활성화할 기존 Hosted Zone ID 목록."
  type        = list(string)
  default     = []
}

# ── Feature Flags ─────────────────────────────────────────────────────────────
# 해당 서비스가 이미 계정에 활성화되어 있으면 false로 설정하세요.
# 충돌 없이 기존 서비스를 그대로 사용합니다.

variable "enable_guardduty" {
  description = "GuardDuty 활성화. 이미 켜져 있으면 false."
  type        = bool
  default     = true
}

variable "enable_inspector" {
  description = "Inspector v2 활성화. 이미 켜져 있으면 false."
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "AWS Config 활성화. 이미 켜져 있으면 false."
  type        = bool
  default     = true
}

variable "enable_access_analyzer" {
  description = "IAM Access Analyzer 활성화. 이미 켜져 있으면 false."
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Security Hub 활성화 + EventBridge 룰 생성. 이미 켜져 있으면 false."
  type        = bool
  default     = true
}

variable "enable_auto_remediation" {
  description = "Lambda Auto Remediation 활성화 (HIGH/CRITICAL Finding 자동 교정)."
  type        = bool
  default     = true
}

variable "enable_opensearch" {
  description = "OpenSearch 도메인 + OSIS 파이프라인 생성. false면 SIEM 없이 S3에만 저장."
  type        = bool
  default     = true
}

variable "enable_amp" {
  description = "Amazon Managed Prometheus (AMP) 활성화. Grafana와 함께 사용."
  type        = bool
  default     = false
}

# ── SaaS 통합 ──────────────────────────────────────────────────────────────────

variable "saas_apps" {
  description = <<-EOT
    AppFabric으로 통합할 SaaS 앱 목록.
    항목 추가 → AppFabric Authorization + Ingestion + S3 Destination 자동 생성.
    항목 삭제 → 해당 리소스 자동 삭제.

    credential_secret_arn: Secrets Manager에 {"client_id":"...","client_secret":"..."} 형태로 저장.
    app_type 고정값: GITHUB, ATLASSIAN, GOOGLEWORKSPACE, SALESFORCE, SLACK, ZOOM, DROPBOX, BOX, ASANA, MONDAY
  EOT
  type = list(object({
    name                  = string
    app_type              = string
    credential_secret_arn = string
    tenant_id             = optional(string, "")
  }))
  default = []
}

# ── 온프레미스 통합 ────────────────────────────────────────────────────────────

variable "onprem_sources" {
  description = <<-EOT
    온프레미스 로그 소스 목록.
    항목 추가 → Kinesis Firehose 스트림 + IAM User + Secrets Manager 시크릿 자동 생성.
    existing_iam_role_arn을 입력하면 IAM User/Access Key 생성 없이 해당 Role로 인증합니다.
    배포 후 output의 onprem_fluentbit_configs로 FluentBit 설정을 확인하세요.
  EOT
  type = list(object({
    name                  = string
    description           = optional(string, "")
    log_prefix            = string
    existing_iam_role_arn = optional(string, "")
  }))
  default = []
}

variable "cloudwatch_log_retention_days" {
  description = "Lambda, Firehose 등 모듈 내부 CloudWatch Log Group 보존 기간 (일)."
  type        = number
  default     = 14
}

# ── Alerting: Slack ─────────────────────────────────────────────────────────────

variable "slack_webhook_url" {
  description = "Slack Incoming Webhook URL. 비우면 Slack Lambda를 생성하지 않습니다."
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack 알림 채널."
  type        = string
  default     = "#security-alerts"
}

# ── Alerting: Jira ──────────────────────────────────────────────────────────────

variable "jira_url" {
  description = "Jira 인스턴스 URL. 예: https://myco.atlassian.net. 비우면 Jira Lambda를 생성하지 않습니다."
  type        = string
  default     = ""
}

variable "jira_api_token_secret_arn" {
  description = "Jira 자격증명 Secrets Manager ARN. {\"email\":\"...\",\"api_token\":\"...\"} 형태."
  type        = string
  default     = ""
}

variable "jira_project_key" {
  description = "보안 이슈를 생성할 Jira 프로젝트 키."
  type        = string
  default     = "SEC"
}

variable "jira_issue_type" {
  description = "생성할 Jira 이슈 타입."
  type        = string
  default     = "Bug"
}

# ── OpenSearch 사이즈 ───────────────────────────────────────────────────────────

variable "opensearch_instance_type" {
  description = "OpenSearch 데이터 노드 인스턴스 타입."
  type        = string
  default     = "r6g.large.search"
}

variable "opensearch_instance_count" {
  description = "OpenSearch 데이터 노드 수. 2 이상이면 Multi-AZ 자동 설정."
  type        = number
  default     = 2
}

variable "opensearch_ebs_volume_size" {
  description = "OpenSearch EBS 볼륨 크기 (GiB)."
  type        = number
  default     = 100
}

variable "opensearch_admin_secret_arn" {
  description = <<-EOT
    직접 생성한 OpenSearch admin 자격증명 Secrets Manager ARN.
    입력하면 모듈이 비밀번호와 Secret을 자동 생성하지 않습니다.
    비워두면 모듈이 random 비밀번호를 생성하고 Secrets Manager에 저장합니다.
    Secret 형식: {"username":"admin","password":"your-password"}
  EOT
  type        = string
  default     = ""
}

variable "opensearch_security_group_ids" {
  description = <<-EOT
    OpenSearch에 적용할 기존 Security Group ID 목록.
    입력하면 모듈이 Security Group을 새로 만들지 않습니다.
    비워두면 VPC CIDR에서 포트 443만 허용하는 SG를 자동 생성합니다.
  EOT
  type        = list(string)
  default     = []
}

variable "opensearch_log_retention_days" {
  description = "OpenSearch CloudWatch Log Group 보존 기간 (일)."
  type        = number
  default     = 7
}

# ── S3 로그 보존 ────────────────────────────────────────────────────────────────

variable "log_retention_days" {
  description = "S3 Standard 보존 기간 (일). 이후 Intelligent-Tiering으로 전환."
  type        = number
  default     = 90
}

variable "log_glacier_days" {
  description = "Glacier IR 전환 시점 (일). 이후 3년 뒤 자동 만료."
  type        = number
  default     = 365
}

# ── Monitoring ──────────────────────────────────────────────────────────────────

variable "grafana_workspace_id" {
  description = "AMP에 연결할 Grafana Workspace ID. enable_amp = true 시 사용."
  type        = string
  default     = ""
}

# ── 공통 ────────────────────────────────────────────────────────────────────────

variable "tags" {
  description = "모든 리소스에 추가할 태그."
  type        = map(string)
  default     = {}
}
