variable "project" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경 (dev / stg / prod)"
  type        = string
}

variable "iam_user_name" {
  description = "생성할 IAM 유저 이름"
  type        = string
}

variable "s3_app_bucket_id" {
  description = "App 버킷 ID (버킷 정책 적용 대상)"
  type        = string
}

variable "s3_app_bucket_arn" {
  description = "App 버킷 ARN (EC2 Role 권한 및 버킷 정책에 사용)"
  type        = string
}

variable "github_repo" {
  description = "GitHub Actions OIDC 허용할 레포 (예: your-org/your-repo)"
  type        = string
}
