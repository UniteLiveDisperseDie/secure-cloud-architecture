variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "secrets_arn" {
  type = string
}

variable "s3_app_bucket_arn" {
  type = string
}

variable "rds_kms_key_arn" {
  type = string
}

variable "secrets_kms_key_arn" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_repo" {
  type = string
}
