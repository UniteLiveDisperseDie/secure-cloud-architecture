# Common
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev / stg / prod)"
  type        = string
}

variable "domain_name" {
  description = "Domain name registered in Route53 (e.g., example.com)"
  type        = string
}

# S3
variable "s3_frontend_bucket_name" {
  description = "Name of the S3 bucket for static resources"
  type        = string
}

# CloudFront
variable "cloudfront_price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_200"
}

variable "alb_dns_name" {
  description = "ALB DNS name (output from the network module)"
  type        = string
}

variable "cloudfront_shared_secret" {
  description = "Shared secret value for CloudFront to ALB custom header (injected from the security module)"
  type        = string
  sensitive   = true
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (us-east-1, output from the dns module)"
  type        = string
}

variable "web_acl_arn" {
  description = "WAFv2 Web ACL ARN for CloudFront"
  type        = string
}
