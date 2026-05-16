provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  cloudfront_origin_secret_id = coalesce(var.cloudfront_origin_secret_name, "${var.project}/${var.environment}/origin-secret")
  cloudtrail_arn              = "arn:aws:cloudtrail:${var.region}:${data.aws_caller_identity.current.account_id}:trail/${var.project}-${var.environment}-org-trail"
}

# ──────────────────────────────────────────
# KMS CMKs (Production Account)
# rds-cmk, s3-cmk, secrets-cmk, ebs-cmk
# ──────────────────────────────────────────
module "kms" {
  source = "./modules/kms"

  project               = var.project
  environment           = var.environment
  security_account_id   = var.security_account_id
  production_account_id = data.aws_caller_identity.current.account_id
}

# ──────────────────────────────────────────
# DNS / ACM
# ──────────────────────────────────────────
module "dns" {
  source = "./modules/dns"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project     = var.project
  environment = var.environment
  domain_name = var.domain_name
}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "cloudfront_root" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cdn.cloudfront_domain_name
    zone_id                = module.cdn.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# ──────────────────────────────────────────
# Secrets Manager
# ──────────────────────────────────────────
module "secrets" {
  source = "./modules/security/secrets"

  project     = var.project
  environment = var.environment

  db_username      = var.db_username
  db_name          = var.db_name
  secrets_kms_key_arn = module.kms.secrets_key_arn

  depends_on = [module.kms]
}

# CloudFront ↔ ALB 공유 시크릿
resource "random_password" "cloudfront_origin_secret" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "cloudfront_origin" {
  name       = local.cloudfront_origin_secret_id
  kms_key_id = module.kms.secrets_key_arn

  tags = {
    Name        = "${var.project}-${var.environment}-origin-secret"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "cloudfront_origin" {
  secret_id     = aws_secretsmanager_secret.cloudfront_origin.id
  secret_string = random_password.cloudfront_origin_secret.result
}

# ──────────────────────────────────────────
# IAM (ECS Task Role, Instance Profile, GitHub OIDC)
# ──────────────────────────────────────────
module "iam" {
  source = "./modules/security/iam"

  project     = var.project
  environment = var.environment

  secrets_arn         = module.secrets.db_secret_arn
  s3_app_bucket_arn   = aws_s3_bucket.app.arn
  rds_kms_key_arn     = module.kms.rds_key_arn
  secrets_kms_key_arn = module.kms.secrets_key_arn
  github_org          = var.github_org
  github_repo         = var.github_repo

  depends_on = [module.kms, module.secrets]
}

# ──────────────────────────────────────────
# App S3 버킷 (ECS Task가 사용, s3-cmk 암호화)
# ──────────────────────────────────────────
resource "aws_s3_bucket" "app" {
  bucket = var.s3_app_bucket_name

  tags = {
    Name        = var.s3_app_bucket_name
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket                  = aws_s3_bucket.app.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = module.kms.s3_key_arn
    }
    bucket_key_enabled = true
  }
}

# ──────────────────────────────────────────
# Network (VPC 3계층, NACL, ALB, SG, Endpoints, FlowLogs)
# ──────────────────────────────────────────
module "network" {
  source = "./modules/network"

  project     = var.project
  environment = var.environment

  vpc_cidr             = var.vpc_cidr
  availability_zone_a  = var.availability_zones[0]
  availability_zone_b  = var.availability_zones[1]
  public_subnet_cidr_a = var.public_subnet_cidrs[0]
  public_subnet_cidr_b = var.public_subnet_cidrs[1]
  private_subnet_cidr_a = var.private_subnet_cidrs[0]
  private_subnet_cidr_b = var.private_subnet_cidrs[1]
  db_subnet_cidr_a     = var.db_subnet_cidrs[0]
  db_subnet_cidr_b     = var.db_subnet_cidrs[1]

  alb_certificate_arn      = module.dns.alb_certificate_arn
  cloudfront_shared_secret = random_password.cloudfront_origin_secret.result

  log_archive_bucket_arn  = var.log_archive_bucket_arn
  log_archive_bucket_name = var.log_archive_bucket_name

  depends_on = [module.dns, aws_secretsmanager_secret_version.cloudfront_origin]
}

# ──────────────────────────────────────────
# Compute (ECS on EC2)
# ──────────────────────────────────────────
module "compute" {
  source = "./modules/compute"

  project     = var.project
  environment = var.environment

  private_subnet_ids       = module.network.private_subnet_ids
  ecs_security_group_id    = module.network.ecs_security_group_id
  alb_target_group_arn     = module.network.target_group_arn
  ecs_instance_profile_name = module.iam.ecs_instance_profile_name
  ecs_task_role_arn        = module.iam.ecs_task_role_arn
  ecs_execution_role_arn   = module.iam.ecs_execution_role_arn

  ebs_kms_key_arn          = module.kms.ebs_key_arn
  secrets_arn              = module.secrets.db_secret_arn

  instance_type            = var.instance_type
  asg_min_size             = var.asg_min_size
  asg_max_size             = var.asg_max_size
  asg_desired_capacity     = var.asg_desired_capacity

  container_image          = var.container_image
  container_port           = var.container_port

  depends_on = [module.network, module.iam, module.secrets]
}

# ──────────────────────────────────────────
# Database (RDS Multi-AZ + ElastiCache)
# ──────────────────────────────────────────
module "database" {
  source = "./modules/database"

  project     = var.project
  environment = var.environment

  db_subnet_ids          = module.network.db_subnet_ids
  db_security_group_id   = module.network.db_security_group_id
  cache_security_group_id = module.network.cache_security_group_id

  db_instance_class      = var.db_instance_class
  db_engine              = var.db_engine
  db_engine_version      = var.db_engine_version
  db_allocated_storage   = var.db_allocated_storage
  db_secret_id           = module.secrets.db_secret_id
  rds_kms_key_arn        = module.kms.rds_key_arn

  cache_node_type        = var.cache_node_type
  cache_auth_token       = random_password.cache_auth_token.result

  depends_on = [module.network, module.secrets, module.kms]
}

resource "random_password" "cache_auth_token" {
  length  = 32
  special = false
}

# ──────────────────────────────────────────
# WAF (us-east-1, CloudFront 연결)
# ──────────────────────────────────────────
module "waf" {
  source = "./modules/security/waf"

  providers = {
    aws = aws.us_east_1
  }

  project     = var.project
  environment = var.environment

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ──────────────────────────────────────────
# CDN (CloudFront + S3 Frontend)
# ──────────────────────────────────────────
module "cdn" {
  source = "./modules/cdn"

  project     = var.project
  environment = var.environment

  domain_name             = var.domain_name
  s3_frontend_bucket_name = var.s3_frontend_bucket_name
  cloudfront_price_class  = var.cloudfront_price_class

  alb_dns_name             = module.network.alb_dns_name
  acm_certificate_arn      = module.dns.acm_certificate_arn
  cloudfront_shared_secret = random_password.cloudfront_origin_secret.result
  s3_cmk_key_arn           = module.kms.s3_key_arn
  web_acl_arn              = module.waf.web_acl_arn

  depends_on = [module.waf, aws_secretsmanager_secret_version.cloudfront_origin]
}

# ──────────────────────────────────────────
# Observability (CloudTrail Org Trail + CloudWatch)
# ──────────────────────────────────────────
module "observability" {
  source = "./modules/observability"

  project     = var.project
  environment = var.environment

  log_archive_bucket_name      = var.log_archive_bucket_name
  log_archive_bucket_arn       = var.log_archive_bucket_arn
  cloudtrail_kms_key_arn       = var.log_archive_kms_key_arn
  cloudwatch_log_retention_days = var.cloudwatch_log_retention_days
  alarm_email                  = var.alarm_email

  alb_arn          = module.network.alb_arn
  ecs_cluster_name = module.compute.ecs_cluster_name
  asg_name         = module.compute.asg_name
}

# ──────────────────────────────────────────
# AWS Config (Production Account)
# ──────────────────────────────────────────
module "config" {
  source = "./modules/security/config"

  project     = var.project
  environment = var.environment

  log_archive_bucket_name = var.log_archive_bucket_name
  sns_topic_arn           = module.observability.ops_sns_topic_arn

  depends_on = [module.observability]
}
