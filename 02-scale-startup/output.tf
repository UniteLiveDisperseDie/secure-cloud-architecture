output "application_url" {
  description = "Primary application URL"
  value       = "https://${var.domain_name}"
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cdn.cloudfront_domain_name
}
