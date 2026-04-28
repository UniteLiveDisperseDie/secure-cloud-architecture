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
  description = "Primary AZ (EC2 + ASG가 배치될 AZ)"
  type        = string
}

variable "availability_zone_b" {
  description = "Secondary AZ (ALB 요구사항 충족용 빈 서브넷)"
  type        = string
}

variable "public_subnet_cidr_a" {
  description = "Primary public subnet CIDR (EC2 배치)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_b" {
  description = "Secondary public subnet CIDR (ALB 전용, 트래픽 없음)"
  type        = string
  default     = "10.0.2.0/24"
}

# Security Groups
variable "app_port" {
  description = "Port the app server listens on"
  type        = number
  default     = 8080
}

# ALB
variable "health_check_path" {
  description = "Health check path for the target group"
  type        = string
  default     = "/health"
}

variable "alb_certificate_arn" {
  description = "ACM certificate ARN (dns 모듈 output)"
  type        = string
}


