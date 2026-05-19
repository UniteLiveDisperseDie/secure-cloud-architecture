# ──────────────────────────────────────────
# 공통
# ──────────────────────────────────────────
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

# ──────────────────────────────────────────
# IAM User
# ──────────────────────────────────────────
variable "iam_users" {
  description = "IAM 유저 목록"
  type        = set(string)
}


# ──────────────────────────────────────────
# 네트워크 (VPC)
# ──────────────────────────────────────────
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "사용할 가용 영역 목록"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 목록"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 목록"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# ──────────────────────────────────────────
# EC2 / Auto Scaling
# ──────────────────────────────────────────
variable "ami_id" {
  description = "App Server에 사용할 AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "asg_min_size" {
  description = "Auto Scaling 최소 인스턴스 수"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Auto Scaling 최대 인스턴스 수"
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "Auto Scaling 희망 인스턴스 수"
  type        = number
  default     = 2
}

# ──────────────────────────────────────────
# 데이터베이스 (RDS)
# ──────────────────────────────────────────
variable "db_engine" {
  description = "DB 엔진 (mysql / postgres 등)"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "DB 엔진 버전"
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.medium"
}

variable "db_name" {
  description = "초기 데이터베이스 이름"
  type        = string
}

variable "db_username" {
  description = "DB 마스터 유저명"
  type        = string
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "DB 스토리지 용량 (GB)"
  type        = number
  default     = 20
}

# ──────────────────────────────────────────
# CloudFront + S3 (정적 호스팅)
# ──────────────────────────────────────────
variable "domain_name" {
  description = "Route 53에 등록된 도메인 이름"
  type        = string
}

variable "subdomain" {
  description = "CloudFront에 연결할 서브도메인"
  type        = string
  default     = "www"
}

variable "cloudfront_price_class" {
  description = "CloudFront 가격 정책"
  type        = string
  default     = "PriceClass_200"
}

variable "s3_frontend_bucket_name" {
  description = "CloudFront origin이 되는 S3 버킷 이름"
  type        = string
}

variable "s3_app_bucket_name" {
  description = "App Server가 사용하는 S3 버킷 이름"
  type        = string
}

variable "s3_log_bucket_name" {
  description = "CloudTrail 로그 저장용 S3 버킷 이름"
  type        = string
}

variable "cloudfront_origin_secret_name" {
  description = "CloudFront -> ALB 공유 시크릿 이름. 기존 시크릿이 손상됐으면 새 이름으로 변경 가능"
  type        = string
  default     = null
}

# ──────────────────────────────────────────
# 모니터링 (CloudWatch / SNS)
# ──────────────────────────────────────────
variable "alarm_email" {
  description = "CloudWatch 알람을 수신할 이메일 주소"
  type        = string
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch 로그 보관 기간 (일)"
  type        = number
  default     = 30
}
