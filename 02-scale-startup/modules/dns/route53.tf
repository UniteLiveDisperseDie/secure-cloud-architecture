# Route 53

# Reference existing hosted zone (Connects here once the domain is created)
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Route53 A records pointing CloudFront are managed in the root main.tf
# to avoid a circular dependency between the dns module and cdn module
# (cdn needs acm_certificate_arn from dns; dns would need cloudfront outputs from cdn)
