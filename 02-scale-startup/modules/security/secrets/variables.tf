variable "project" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경"
  type        = string
}

variable "db_username" {
  description = "DB 마스터 유저명"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
}

variable "recovery_window_in_days" {
  description = "시크릿 삭제 대기 기간 (일), 0일 경우 즉시 삭제"
  type        = number
  default     = 7
}
