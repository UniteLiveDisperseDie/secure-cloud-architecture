variable "project" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "단일 배포 환경"
  type        = string
}

variable "alb_arn" {
  description = "WAF를 연결할 ALB ARN"
  type        = string
}

variable "tags" {
  description = "태그"
  type        = map(string)
  default     = {}
}
