# Common
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev / stg / prod)"
  type        = string
}

# ACM + Route53
variable "domain_name" {
  description = "서비스 도메인 이름 (예: example.com). 없으면 빈 문자열."
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID. 없으면 빈 문자열로 두면 Route53/ACM 검증 생략."
  type        = string
  default     = ""
}
