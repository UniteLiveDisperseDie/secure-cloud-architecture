# ──────────────────────────────────────────
# 공통
# ──────────────────────────────────────────
variable "project" {
  description = "프로젝트 이름"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "allowed_regions" {
  description = "Foundation SCP에서 허용할 리전 목록. IAM/CloudFront/Route53 등 글로벌 서비스 리전(us-east-1) 포함 필수"
  type        = list(string)
  default     = ["ap-northeast-2", "us-east-1"]
}

# ──────────────────────────────────────────
# 계정 ID (7개 계정)
# ──────────────────────────────────────────
variable "security_account_id" {
  description = "Security Account ID"
  type        = string
}

variable "log_archive_account_id" {
  description = "Log Archive Account ID"
  type        = string
}

variable "production_account_id" {
  description = "Production Account ID"
  type        = string
}

variable "staging_account_id" {
  description = "Staging Account ID"
  type        = string
}

variable "development_account_id" {
  description = "Development Account ID"
  type        = string
}

variable "sandbox_account_id" {
  description = "Sandbox Account ID"
  type        = string
}
