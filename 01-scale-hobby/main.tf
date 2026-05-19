terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}


# ──────────────────────────────────────────
# S3 App Bucket
# ──────────────────────────────────────────

resource "aws_s3_bucket" "app" {
  bucket = var.s3_app_bucket_name

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ──────────────────────────────────────────
# Modules
# ──────────────────────────────────────────

module "dns" {
  source = "./modules/dns"

  project        = var.project
  environment    = var.environment
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id
}

module "network" {
  source = "./modules/network"

  project             = var.project
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zone_a = var.availability_zone_a
  availability_zone_b = var.availability_zone_b
  app_port            = var.app_port
  alb_certificate_arn = module.dns.acm_certificate_arn

  depends_on = [module.dns]
}

module "security" {
  source = "./modules/security"

  project           = var.project
  environment       = var.environment
  iam_user_name     = var.iam_user_name
  s3_app_bucket_id  = aws_s3_bucket.app.id
  s3_app_bucket_arn = aws_s3_bucket.app.arn
  github_repo       = var.github_repo

  depends_on = [aws_s3_bucket_public_access_block.app]
}

module "compute" {
  source = "./modules/compute"

  project                   = var.project
  environment               = var.environment
  public_subnet_id          = module.network.public_subnet_id
  sg_ec2_id                 = module.network.sg_ec2_id
  iam_instance_profile_name = module.security.ec2_instance_profile_name

  depends_on = [module.network, module.security]
}

module "observability" {
  source = "./modules/observability"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project     = var.project
  environment = var.environment
  alarm_email = var.alarm_email
}

# ──────────────────────────────────────────
# ALB Target Group Attachment (standalone)
# 순환 참조 방지: network ↔ compute 분리
# ──────────────────────────────────────────

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = module.network.target_group_arn
  target_id        = module.compute.ec2_instance_id
  port             = var.app_port

  depends_on = [module.network, module.compute]
}

# ──────────────────────────────────────────
# Route53 A Record (standalone)
# 순환 참조 방지: dns ↔ network 분리
# 도메인 없으면 생성 생략 (hosted_zone_id = "")
# ──────────────────────────────────────────

resource "aws_route53_record" "alb" {
  count = var.hosted_zone_id != "" ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.network.alb_dns_name
    zone_id                = module.network.alb_zone_id
    evaluate_target_health = true
  }
}

module "waf" {
  source = "./modules/waf"

  project     = var.project
  environment = var.environment
  alb_arn     = module.network.alb_arn
}
