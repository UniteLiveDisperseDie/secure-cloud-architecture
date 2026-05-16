variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "s3_frontend_bucket_name" {
  type = string
}

variable "cloudfront_price_class" {
  type    = string
  default = "PriceClass_200"
}

variable "alb_dns_name" {
  type = string
}

variable "acm_certificate_arn" {
  type = string
}

variable "cloudfront_shared_secret" {
  type      = string
  sensitive = true
}

variable "s3_cmk_key_arn" {
  type = string
}

variable "web_acl_arn" {
  type = string
}
