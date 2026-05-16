variable "name_prefix" {
  type = string
}
variable "logging_bucket_id" {
  type = string
}

variable "logging_bucket_arn" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "r6g.large.search"
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "ebs_volume_size" {
  type    = number
  default = 100
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "jira_lambda_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}

# ── 사용자 제공 자격증명 ──────────────────────────────────────────────────────
# 입력하면 모듈이 random_password + Secrets Manager를 생성하지 않습니다.
# 비워두면 자동으로 생성됩니다.

variable "admin_secret_arn" {
  description = <<-EOT
    직접 만든 OpenSearch admin 자격증명 Secrets Manager ARN.
    입력하면 모듈이 비밀번호와 Secret을 자동 생성하지 않습니다.
    Secret은 아래 형태로 저장되어 있어야 합니다:
    {"username":"admin","password":"your-password"}
  EOT
  type        = string
  default     = ""
}

# ── 사용자 제공 Security Group ────────────────────────────────────────────────
# 입력하면 모듈이 Security Group을 새로 만들지 않습니다.
# 비워두면 VPC CIDR에서 포트 443만 허용하는 SG를 자동 생성합니다.

variable "security_group_ids" {
  description = <<-EOT
    OpenSearch에 적용할 기존 Security Group ID 목록.
    입력하면 모듈이 Security Group을 새로 만들지 않습니다.
    비워두면 VPC CIDR → 443 허용 SG를 자동 생성합니다.
  EOT
  type        = list(string)
  default     = []
}

# ── CloudWatch Log 보존 기간 ──────────────────────────────────────────────────

variable "log_retention_days" {
  description = "OpenSearch CloudWatch Log Group 보존 기간 (일)."
  type        = number
  default     = 7
}
