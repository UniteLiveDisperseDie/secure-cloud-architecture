variable "project" {
  description = "프로젝트 이름"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "alarm_email" {
  description = "보안 알림 이메일"
  type        = string
}

variable "organization_id" {
  description = "AWS Organizations ID"
  type        = string
}
