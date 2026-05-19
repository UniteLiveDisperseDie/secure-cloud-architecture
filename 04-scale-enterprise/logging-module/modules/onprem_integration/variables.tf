variable "name_prefix" {
  type = string
}

variable "logging_bucket_id" {
  type = string
}

variable "logging_bucket_arn" {
  type = string
}

variable "onprem_sources" {
  description = <<-EOT
    온프레미스 로그 소스 목록.
    existing_iam_role_arn을 입력하면 IAM User와 Access Key를 생성하지 않습니다.
    IAM Role은 Firehose PutRecord 권한과 EC2 인스턴스 프로파일 또는
    AssumeRole 트러스트를 갖고 있어야 합니다.
  EOT
  type = list(object({
    name                  = string
    description           = optional(string, "")
    log_prefix            = string
    existing_iam_role_arn = optional(string, "") # 있으면 IAM User + Access Key 생성 안 함
  }))
  default = []
}

variable "log_retention_days" {
  description = "Firehose 오류 로그 CloudWatch Log Group 보존 기간 (일)."
  type        = number
  default     = 14
}

variable "tags" {
  type    = map(string)
  default = {}
}
