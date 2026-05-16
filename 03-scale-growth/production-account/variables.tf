# ──────────────────────────────────────────
# 공통
# ──────────────────────────────────────────
variable "project" {
  type = string
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "security_account_id" {
  description = "Security Account ID (KMS KeyAdminRole cross-account)"
  type        = string
}

variable "github_org" {
  description = "GitHub 조직 이름 (OIDC)"
  type        = string
}

variable "github_repo" {
  description = "GitHub 레포지토리 이름 (OIDC)"
  type        = string
}

# ──────────────────────────────────────────
# 네트워크
# ──────────────────────────────────────────
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR (퍼블릭 A, B)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR (ECS A, B)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "db_subnet_cidrs" {
  description = "DB 서브넷 CIDR (RDS/ElastiCache A, B)"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

# ──────────────────────────────────────────
# ECS on EC2
# ──────────────────────────────────────────
variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "asg_min_size" {
  type    = number
  default = 2
}

variable "asg_max_size" {
  type    = number
  default = 8
}

variable "asg_desired_capacity" {
  type    = number
  default = 2
}

variable "container_image" {
  description = "ECS Task 컨테이너 이미지 URI (ECR ARN)"
  type        = string
}

variable "container_port" {
  description = "컨테이너 포트"
  type        = number
  default     = 8080
}

# ──────────────────────────────────────────
# RDS Multi-AZ
# ──────────────────────────────────────────
variable "db_engine" {
  type    = string
  default = "mysql"
}

variable "db_engine_version" {
  type    = string
  default = "8.0"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type      = string
  sensitive = true
}

variable "db_allocated_storage" {
  type    = number
  default = 100
}

# ──────────────────────────────────────────
# ElastiCache Redis
# ──────────────────────────────────────────
variable "cache_node_type" {
  type    = string
  default = "cache.t3.medium"
}

# ──────────────────────────────────────────
# CDN / DNS
# ──────────────────────────────────────────
variable "domain_name" {
  type = string
}

variable "cloudfront_price_class" {
  type    = string
  default = "PriceClass_200"
}

variable "s3_frontend_bucket_name" {
  type = string
}

variable "s3_app_bucket_name" {
  type = string
}

variable "cloudfront_origin_secret_name" {
  type    = string
  default = null
}

# ──────────────────────────────────────────
# Log Archive 연동 (Cross-account)
# ──────────────────────────────────────────
variable "log_archive_bucket_name" {
  description = "Log Archive Account S3 버킷 이름"
  type        = string
}

variable "log_archive_bucket_arn" {
  description = "Log Archive Account S3 버킷 ARN"
  type        = string
}

variable "log_archive_kms_key_arn" {
  description = "Log Archive KMS 키 ARN (s3-log-cmk)"
  type        = string
}

# ──────────────────────────────────────────
# 모니터링
# ──────────────────────────────────────────
variable "alarm_email" {
  type = string
}

variable "cloudwatch_log_retention_days" {
  type    = number
  default = 90
}
