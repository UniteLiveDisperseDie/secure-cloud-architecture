variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev / stg / prod)"
  type        = string
}

# Domain / ACM
variable "domain_name" {
  description = "Domain name registered in Route53 (e.g., example.com)"
  type        = string
}
