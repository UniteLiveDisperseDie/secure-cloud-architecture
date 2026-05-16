# Common
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev / stg / prod)"
  type        = string
}

# Network
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zone_a" {
  description = "Primary AZ for the app and database tiers"
  type        = string
}

variable "availability_zone_b" {
  description = "Secondary AZ used only for the ALB's additional public subnet"
  type        = string
}

variable "public_subnet_cidr_a" {
  description = "CIDR block for public_a (app subnet)"
  type        = string
}

variable "public_subnet_cidr_b" {
  description = "CIDR block for public_b (kept empty except for the ALB)"
  type        = string
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR block"
  type        = string
}

variable "private_subnet_cidr_b" {
  description = "Secondary private subnet CIDR block for RDS AZ coverage"
  type        = string
}

# Security Groups
variable "app_port" {
  description = "Port the app server listens on"
  type        = number
  default     = 80
}

variable "db_port" {
  description = "Database port (e.g. 3306 for MySQL, 5432 for PostgreSQL)"
  type        = number
  default     = 3306
}

# ALB
variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/health"
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN for ALB HTTPS listener"
  type        = string
}

variable "alb_access_logs_bucket_name" {
  description = "Shared audit/log bucket name used for ALB access logs"
  type        = string
}

# CloudFront가 ALB로 전달하는 X-Origin-Secret 값.
# network 모듈이 Secrets Manager를 직접 조회하지 않고 루트 모듈에서 입력받는다.
variable "cloudfront_shared_secret" {
  description = "Shared secret value inserted by CloudFront and validated by the ALB"
  type        = string
  sensitive   = true
}
