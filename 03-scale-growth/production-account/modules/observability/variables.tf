variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "alarm_email" {
  type = string
}

variable "log_archive_bucket_name" {
  type = string
}

variable "log_archive_bucket_arn" {
  type    = string
  default = ""
}

variable "cloudtrail_kms_key_arn" {
  type = string
}

variable "cloudwatch_log_retention_days" {
  type    = number
  default = 90
}

variable "alb_arn" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "asg_name" {
  type    = string
  default = ""
}
