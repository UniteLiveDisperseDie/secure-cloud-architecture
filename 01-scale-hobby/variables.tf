variable "project" {
  description = "프로젝트 이름 (리소스 태그 및 네이밍에 사용)"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / stg / prod)"
  type        = string
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "iam_user_name" {
  description = "생성할 IAM 유저 이름"
  type        = string
}

variable "s3_app_bucket_name" {
  description = "App Server가 사용하는 S3 버킷 이름"
  type        = string
}

variable "alarm_email" {
  description = "CloudTrail 이벤트 알람을 수신할 이메일 주소"
  type        = string
}

# ──────────────────────────────────────────
# DNS
# ──────────────────────────────────────────

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

# ──────────────────────────────────────────
# Network
# ──────────────────────────────────────────

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_a" {
  description = "Primary AZ (EC2가 배치될 AZ)"
  type        = string
  default     = "ap-northeast-2a"
}

variable "availability_zone_b" {
  description = "Secondary AZ (ALB 요구사항 충족용)"
  type        = string
  default     = "ap-northeast-2c"
}

variable "app_port" {
  description = "앱 서버가 수신하는 포트"
  type        = number
  default     = 8080
}

variable "github_repo" {
  description = "GitHub Actions OIDC 허용할 레포 (예: your-org/your-repo)"
  type        = string
}
