# ──────────────────────────────────────────
# s3-log-cmk
# 사용 주체: CloudTrail Org Trail, Config, VPC Flow Logs, ALB Access Log
# 관리 주체: Security Account KeyAdminRole (Cross-account)
# ──────────────────────────────────────────
resource "aws_kms_key" "s3_log" {
  description             = "s3-log-cmk: Log Archive S3 버킷 로그 암호화"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  multi_region            = false

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.log_archive_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowSecurityAccountKeyAdmin"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.security_account_id}:role/KeyAdminRole"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudTrailEncrypt"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "kms:EncryptionContext:aws:cloudtrail:arn" = [
              "arn:aws:cloudtrail:*:${var.management_account_id}:trail/*",
              "arn:aws:cloudtrail:*:${var.production_account_id}:trail/*",
              "arn:aws:cloudtrail:*:${var.staging_account_id}:trail/*",
              "arn:aws:cloudtrail:*:${var.development_account_id}:trail/*",
              "arn:aws:cloudtrail:*:${var.security_account_id}:trail/*"
            ]
          }
        }
      },
      {
        Sid    = "AllowConfigEncrypt"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowVPCFlowLogsEncrypt"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowELBEncrypt"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::600734575887:root"
        }
        Action   = "kms:GenerateDataKey"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name      = "${var.project}-s3-log-cmk"
    Project   = var.project
    ManagedBy = "terraform"
  }
}

resource "aws_kms_alias" "s3_log" {
  name          = "alias/${var.project}-s3-log-cmk"
  target_key_id = aws_kms_key.s3_log.key_id
}
