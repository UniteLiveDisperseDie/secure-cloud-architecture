variable "name_prefix" {
  type = string
}

variable "logging_bucket_id" {
  type = string
}

variable "logging_bucket_arn" {
  type = string
}

variable "waf_acl_arn" {
  type    = string
  default = ""
}

variable "vpc_ids" {
  type    = list(string)
  default = []
}

variable "alb_arns" {
  type    = list(string)
  default = []
}

variable "route53_zone_ids" {
  type    = list(string)
  default = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
