# ──────────────────────────────────────────
# 중앙 로그 S3 버킷
# ──────────────────────────────────────────
resource "aws_s3_bucket" "logs" {
  # object_lock_enabled = true로 설정해야 Object Lock 쫐을 활성화할 수 있다
  bucket              = var.log_bucket_name
  object_lock_enabled = true

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name      = var.log_bucket_name
    Project   = var.project
    ManagedBy = "terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE-KMS 암호화 (s3-log-cmk)
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

# Object Lock 설정 (COMPLIANCE 모드: 관리자도 삭제 불가)
# GOVERNANCE 모드는 s3:BypassGovernanceRetention 권한이 있으면 우회 가능
resource "aws_s3_bucket_object_lock_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 365
    }
  }
}

# 스토리지 계층화: Standard 90일 → Glacier 1년 → Glacier Deep Archive 장기
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "cloudtrail-lifecycle"
    status = "Enabled"

    filter {
      prefix = "cloudtrail/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }

  rule {
    id     = "vpc-flow-logs-lifecycle"
    status = "Enabled"

    filter {
      prefix = "vpc-flow-logs/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }

  rule {
    id     = "alb-access-logs-lifecycle"
    status = "Enabled"

    filter {
      prefix = "alb-access-logs/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }

  rule {
    id     = "config-history-lifecycle"
    status = "Enabled"

    filter {
      prefix = "config-history/"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

# 버킷 정닝: CloudTrail Org Trail, VPC Flow Logs, ALB Access Log, Config 쓰기 허용
resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

  depends_on = [aws_s3_bucket_public_access_block.logs]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudTrailOrgTrailACLCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${var.log_bucket_name}"
      },
      {
        Sid    = "AllowCloudTrailOrgTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.log_bucket_name}/cloudtrail/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AllowConfigWrite"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "s3:GetBucketAcl",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.log_bucket_name}",
          "arn:aws:s3:::${var.log_bucket_name}/config-history/AWSLogs/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = [
              var.management_account_id,
              var.production_account_id,
              var.staging_account_id,
              var.development_account_id,
              var.security_account_id
            ]
          }
        }
      },
      {
        Sid    = "AllowVPCFlowLogsWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.log_bucket_name}/vpc-flow-logs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AllowVPCFlowLogsACLCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${var.log_bucket_name}"
      },
      {
        # 서울 ELB Account ID (ap-northeast-2 지역)
        Sid    = "AllowALBAccessLog"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::600734575887:root"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.log_bucket_name}/alb-access-logs/*"
      },
      {
        Sid       = "DenyDeleteObject"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:DeleteBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.log_bucket_name}",
          "arn:aws:s3:::${var.log_bucket_name}/*"
        ]
      },
      {
        Sid       = "DenyNonHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          "arn:aws:s3:::${var.log_bucket_name}",
          "arn:aws:s3:::${var.log_bucket_name}/*"
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
