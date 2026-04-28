# Common
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev / stg / prod)"
  type        = string
}

# Network (networking 모듈 output)
variable "public_subnet_id" {
  description = "EC2가 배치될 퍼블릭 서브넷 ID (networking 모듈의 public_subnet_id output)"
  type        = string
}

variable "sg_ec2_id" {
  description = "EC2에 적용할 보안 그룹 ID"
  type        = string
}

# IAM (security 모듈 output)
variable "iam_instance_profile_name" {
  description = "EC2에 부여할 IAM Instance Profile 이름 (security 모듈 output)"
  type        = string
}
