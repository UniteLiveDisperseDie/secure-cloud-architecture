locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# CloudFront OAC (Origin Access Control)
resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project}-${var.environment}-oac"
  description                       = "OAC for S3 static frontend"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2"
  price_class         = var.cloudfront_price_class
  aliases             = [var.domain_name]
  comment             = "${var.project}-${var.environment} distribution"
  default_root_object = "index.html"
  web_acl_id          = var.web_acl_arn # WAF Web ACL ARN 전달

  # Origin 1: S3 (Static Resources)
  origin {
    origin_id                = "S3Origin"
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
  }

  # Origin 2: ALB (Dynamic Requests)
  # Block direct access to ALB: Inject X-Origin-Secret custom header.
  # Requests without this header will return a 403 via ALB Listener Rules.
  # The Shared Secret is managed within Secrets Manager.
  origin {
    origin_id   = "ALBOrigin"
    domain_name = var.alb_dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only" # Enforce HTTPS for the ALB segment
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Origin-Secret"
      value = var.cloudfront_shared_secret
    }
  }

  # Cache Behavior 1: Static Resources (/static/*)
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id
  }

  # Cache Behavior 2: API Requests (/api/*)
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "ALBOrigin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # Disable caching for API requests
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  # Default Cache Behavior: All other requests → ALB
  default_cache_behavior {
    target_origin_id       = "ALBOrigin"
    viewer_protocol_policy = "redirect-to-https" # Redirect HTTP to HTTPS
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  # Restrict access to KR (South Korea) only
  # Small-scale domestic service. Block malicious traffic from overseas.
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["KR"]
    }
  }

  # SSL Certificate (ACM in us-east-1)
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021" # Block TLS 1.0/1.1
  }

  # Shield Standard is automatically applied
  # L3/L4 DDoS protection is automatically enabled when using CloudFront
  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-cloudfront"
  })
}

# CloudFront Managed Cache Policies (Data Sources)

# Caching Optimized (For static resources)
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

# Caching Disabled (For API and dynamic requests)
data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

# Forward all viewer information to Origin (For ALB integration)
data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}
