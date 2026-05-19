variable "project" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / stg / prod)"
  type        = string
}

variable "alarm_email" {
  description = "알람을 수신할 이메일 주소"
  type        = string
}
