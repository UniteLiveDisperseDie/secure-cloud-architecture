variable "project" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경"
  type        = string
}

variable "users" {
  description = "생성할 IAM 유저 목록"
  type        = set(string)
}

variable "s3_app_bucket_arn" {
  description = "App Server가 접근할 S3 버킷 ARN"
  type        = string
}

variable "secrets_arn" {
  description = "Secrets Manager ARN (EC2가 읽을 수 있도록)"
  type        = string
}
