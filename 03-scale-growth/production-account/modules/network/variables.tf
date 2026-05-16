variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type    = string
  default = "ap-northeast-2"
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zone_a" {
  type = string
}

variable "availability_zone_b" {
  type = string
}

variable "public_subnet_cidr_a" {
  type = string
}

variable "public_subnet_cidr_b" {
  type = string
}

variable "private_subnet_cidr_a" {
  type = string
}

variable "private_subnet_cidr_b" {
  type = string
}

variable "db_subnet_cidr_a" {
  type = string
}

variable "db_subnet_cidr_b" {
  type = string
}

variable "alb_certificate_arn" {
  type = string
}

variable "cloudfront_shared_secret" {
  type      = string
  sensitive = true
}

variable "log_archive_bucket_name" {
  type = string
}

variable "log_archive_bucket_arn" {
  type = string
}
