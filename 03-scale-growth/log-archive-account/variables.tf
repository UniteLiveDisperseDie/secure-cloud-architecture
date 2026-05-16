variable "project" {
  description = "프로젝트 이름"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "log_bucket_name" {
  description = "중앙 로그 S3 버킷 이름"
  type        = string
}

variable "management_account_id" {
  description = "Management Account ID (CloudTrail Organization Trail 속스 계정)"
  type        = string
}

variable "security_account_id" {
  description = "Security Account ID"
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
