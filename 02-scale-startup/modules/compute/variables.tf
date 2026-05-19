variable "environment" {
  description = "배포 환경 (dev / stg / prod)"
  type        = string
}

variable "public_subnet_ids" {
  description = "ASG가 배치될 퍼블릭 서브넷 ID 목록"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "RDS가 배치될 프라이빗 서브넷 ID 목록"
  type        = list(string)
}

variable "app_security_group_ids" {
  description = "App Server에 적용할 보안 그룹 ID 목록"
  type        = list(string)
}

variable "alb_target_group_arn" {
  description = "ASG가 연결될 ALB 타겟 그룹 ARN (networking 모듈 output)"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "App Server에 부여할 IAM 인스턴스 프로파일 이름 (security 모듈 output)"
  type        = string
}


variable "tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
  default = {
    Project   = "my-project"
    ManagedBy = "terraform"
  }
}
