provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# 현재 AWS 계정 ID를 조회한다.
# CloudTrail S3 bucket policy의 AWSLogs/<account-id> 경로와 SourceArn 조건에 사용한다.
data "aws_caller_identity" "current" {}

# 공통 계산값
# - cloudfront_origin_secret_id: origin secret 이름을 변수로 override할 수 있게 한다.
# - cloudtrail_arn: CloudTrail이 로그 버킷에 쓸 수 있도록 bucket policy에서 trail ARN을 제한할 때 사용한다.
locals {
  cloudfront_origin_secret_id = coalesce(var.cloudfront_origin_secret_name, "${var.project}/${var.environment}/origin-secret")
  cloudtrail_arn              = "arn:aws:cloudtrail:${var.region}:${data.aws_caller_identity.current.account_id}:trail/${var.project}-${var.environment}-trail"
}

# ──────────────────────────────────────────
# DNS / ACM
# 의존성 없음
# CloudFront(us-east-1)와 ALB(ap-northeast-2) 각각의 인증서를 발급
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

# CloudFront → Route53 A 레코드
# dns/route53.tf의 cloudfront 레코드는 cdn 모듈과의 순환 의존성으로 인해 여기서 관리
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
# Network
# 의존성: dns (alb_certificate_arn)
# ──────────────────────────────────────────
module "network" {
  source = "./modules/network"

  project     = var.project
  environment = var.environment

  vpc_cidr              = var.vpc_cidr
  availability_zone_a   = var.availability_zones[0]
  availability_zone_b   = var.availability_zones[1]
  public_subnet_cidr_a  = var.public_subnet_cidrs[0]
  public_subnet_cidr_b  = var.public_subnet_cidrs[1]
  private_subnet_cidr   = var.private_subnet_cidrs[0]
  private_subnet_cidr_b = var.private_subnet_cidrs[1]

  alb_certificate_arn         = module.dns.alb_certificate_arn
  alb_access_logs_bucket_name = aws_s3_bucket.logs.id
  cloudfront_shared_secret    = random_password.cloudfront_origin_secret.result

  depends_on = [
    aws_secretsmanager_secret_version.cloudfront_origin,
    aws_s3_bucket_policy.logs,
  ]
}

# ──────────────────────────────────────────
# Secrets
# 의존성 없음
# DB 접속 정보를 Secrets Manager에 저장
# ──────────────────────────────────────────
module "secrets" {
  source = "./modules/security/secrets"

  project     = var.project
  environment = var.environment

  db_username = var.db_username
  db_name     = var.db_name
}

# ──────────────────────────────────────────
# CloudFront ↔ ALB 공유 시크릿
# 의존성 없음
# CloudFront가 ALB로 요청 시 X-Origin-Secret 헤더에 삽입
# 동일한 값을 Secrets Manager에도 저장하고, ALB 규칙에도 직접 주입한다.
# ──────────────────────────────────────────
resource "random_password" "cloudfront_origin_secret" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "cloudfront_origin" {
  # kms_key_id를 지정하지 않으면 Secrets Manager의 AWS managed key
  # (aws/secretsmanager)로 암호화된다.
  name = local.cloudfront_origin_secret_id

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

moved {
  from = module.observability.aws_s3_bucket.logs
  to   = aws_s3_bucket.logs
}

# ──────────────────────────────────────────
# App S3 버킷
# 의존성 없음
# EC2가 사용하는 애플리케이션용 S3 버킷 (별도 모듈 없이 직접 생성)
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
  bucket = aws_s3_bucket.app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  bucket = aws_s3_bucket.app.id

  rule {
    # AES256은 S3 관리형 키를 사용하는 SSE-S3 암호화다.
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# ──────────────────────────────────────────
# Audit / Log S3 버킷
# 의존성 없음
# ALB Access Log와 CloudTrail을 함께 저장하는 감사 로그 버킷
# ──────────────────────────────────────────
resource "aws_s3_bucket" "logs" {
  bucket = var.s3_log_bucket_name

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = var.s3_log_bucket_name
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    # AES256은 S3 관리형 키를 사용하는 SSE-S3 암호화다.
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  depends_on = [aws_s3_bucket_public_access_block.logs]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = local.cloudtrail_arn
          }
        }
      },
      {
        Sid    = "AllowCloudTrailACLCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = local.cloudtrail_arn
          }
        }
      },
      {
        Sid    = "AllowALBWrite"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::600734575887:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/alb/*"
      },
      {
        Sid       = "DenyDelete"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:DeleteObject",
          "s3:DeleteBucket"
        ]
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
      },
      {
        Sid       = "DenyNonHttps"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ──────────────────────────────────────────
# IAM
# 의존성: secrets, app/log S3 버킷
# ──────────────────────────────────────────
module "iam" {
  source = "./modules/security/iam"

  project     = var.project
  environment = var.environment

  users             = var.iam_users
  s3_app_bucket_arn = aws_s3_bucket.app.arn
  secrets_arn       = module.secrets.secret_arn
}

# ──────────────────────────────────────────
# Compute
# 의존성: network, iam
# ──────────────────────────────────────────
module "compute" {
  source = "./modules/compute"

  environment = var.environment

  public_subnet_ids      = module.network.public_subnet_ids
  private_subnet_ids     = module.network.private_subnet_ids
  app_security_group_ids = module.network.app_security_group_ids
  alb_target_group_arn   = module.network.target_group_arn

  iam_instance_profile_name = module.iam.ec2_instance_profile_name

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ──────────────────────────────────────────
# Database
# 의존성: network, secrets
# ──────────────────────────────────────────
module "database" {
  source = "./modules/database"
  availability_zone = var.availability_zones[0]
  environment = var.environment

  public_subnet_ids     = module.network.public_subnet_ids
  private_subnet_ids    = module.network.private_subnet_ids
  db_security_group_ids = module.network.db_security_group_ids

  db_instance_class = var.db_instance_class
  db_secret_id      = module.secrets.secret_id

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  depends_on = [module.secrets]
}

# ──────────────────────────────────────────
# Observability
# 의존성: network, compute
# CloudTrail, CloudWatch 알람, SNS 토픽 생성
# ──────────────────────────────────────────
module "observability" {
  source = "./modules/observability"

  project     = var.project
  environment = var.environment

  s3_log_bucket_name            = aws_s3_bucket.logs.id
  s3_log_bucket_arn             = aws_s3_bucket.logs.arn
  cloudwatch_log_retention_days = var.cloudwatch_log_retention_days
  alarm_email                   = var.alarm_email

  alb_arn  = module.network.alb_arn
  asg_name = module.compute.asg_name

  depends_on = [aws_s3_bucket_policy.logs]
}

# ──────────────────────────────────────────
# CDN
# 의존성: network, dns, cloudfront_origin_secret
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

  web_acl_arn = module.waf.web_acl_arn

  depends_on = [aws_secretsmanager_secret_version.cloudfront_origin]
}

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
