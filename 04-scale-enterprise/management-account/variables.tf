variable "region" {
  description = "AWS region for the provider"
  type        = string
  default     = "ap-northeast-2"
}

variable "org_id" {
  description = "AWS Organizations Organization ID (예: o-xxxxxxxxxx)"
  type        = string
}

variable "allowed_regions" {
  description = "전 계정에 허용할 AWS 리전 목록"
  type        = list(string)
  default     = ["ap-northeast-2", "us-east-1"]
}

# ─── Security OU 계정 ─────────────────────────────────────────────────────────
variable "log_archive_account_id" {
  description = "Log Archive 계정 ID"
  type        = string
}

variable "audit_account_id" {
  description = "Audit 계정 ID"
  type        = string
}

variable "security_tooling_account_id" {
  description = "Security Tooling 계정 ID (GuardDuty/SecurityHub 위임 관리자)"
  type        = string
}

# ─── Infrastructure OU 계정 ───────────────────────────────────────────────────
variable "network_account_id" {
  description = "Network 계정 ID (VPC/TGW/Route53 전담)"
  type        = string
}

variable "shared_services_account_id" {
  description = "Shared Services 계정 ID (ECR/AMI/SSM 전담)"
  type        = string
}

variable "backup_account_id" {
  description = "Backup 계정 ID (AWS Backup 전담)"
  type        = string
}

# ─── Production OU 계정 ───────────────────────────────────────────────────────
variable "prod_app_account_id" {
  description = "Prod App 계정 ID"
  type        = string
}

# ─── Non-Production OU 계정 ───────────────────────────────────────────────────
variable "staging_app_account_id" {
  description = "Staging App 계정 ID"
  type        = string
}

variable "staging_data_account_id" {
  description = "Staging Data 계정 ID"
  type        = string
}

variable "dev_team_account_id" {
  description = "Dev Team 계정 ID"
  type        = string
}

# ─── Sandbox OU 계정 ──────────────────────────────────────────────────────────
variable "sandbox_account_id" {
  description = "Dev Sandbox 계정 ID"
  type        = string
}
