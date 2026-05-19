# ──────────────────────────────────────────
# Production Account KMS CMK 4개
# 관리자: Security Account KeyAdminRole (cross-account)
# ──────────────────────────────────────────
locals {
  key_admin_principal = "arn:aws:iam::${var.security_account_id}:role/KeyAdminRole"
  key_root_principal  = "arn:aws:iam::${var.production_account_id}:root"
}

# 공통 키 정력 템플릿
locals {
  common_key_policy_statements = [
    {
      Sid    = "EnableRootAccess"
      Effect = "Allow"
      Principal = { AWS = local.key_root_principal }
      Action   = "kms:*"
      Resource = "*"
    },
    {
      Sid    = "AllowSecurityAccountKeyAdmin"
      Effect = "Allow"
      Principal = { AWS = local.key_admin_principal }
      Action = [
        "kms:Create*", "kms:Describe*", "kms:Enable*", "kms:List*",
        "kms:Put*", "kms:Update*", "kms:Revoke*", "kms:Disable*",
        "kms:Get*", "kms:Delete*", "kms:TagResource", "kms:UntagResource",
        "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion"
      ]
      Resource = "*"
    }
  ]
}

# rds-cmk: RDS 인스턴스 + 스냅샷 암호화
resource "aws_kms_key" "rds" {
  description             = "rds-cmk: RDS Multi-AZ 인스턴스 + 스냅샷 암호화"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(local.common_key_policy_statements, [
      {
        Sid    = "AllowRDSServiceUse"
        Effect = "Allow"
        Principal = { Service = "rds.amazonaws.com" }
        Action = ["kms:GenerateDataKey*", "kms:Decrypt", "kms:DescribeKey", "kms:CreateGrant"]
        Resource = "*"
      }
    ])
  })

  tags = { Name = "${var.project}-${var.environment}-rds-cmk", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project}-${var.environment}-rds-cmk"
  target_key_id = aws_kms_key.rds.key_id
}

# s3-cmk: S3 버킷 (정적 에셋) 암호화
resource "aws_kms_key" "s3" {
  description             = "s3-cmk: S3 정적 에셋 버킷 + App 버킷 암호화"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(local.common_key_policy_statements, [
      {
        Sid    = "AllowS3ServiceUse"
        Effect = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action = ["kms:GenerateDataKey*", "kms:Decrypt", "kms:DescribeKey"]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudFrontUse"
        Effect = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action = ["kms:GenerateDataKey*", "kms:Decrypt", "kms:DescribeKey"]
        Resource = "*"
      }
    ])
  })

  tags = { Name = "${var.project}-${var.environment}-s3-cmk", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project}-${var.environment}-s3-cmk"
  target_key_id = aws_kms_key.s3.key_id
}

# secrets-cmk: Secrets Manager 시크릿 암호화
resource "aws_kms_key" "secrets" {
  description             = "secrets-cmk: Secrets Manager (DB 크레덴셜, X-Origin-Secret, API Key)"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(local.common_key_policy_statements, [
      {
        Sid    = "AllowSecretsManagerUse"
        Effect = "Allow"
        Principal = { Service = "secretsmanager.amazonaws.com" }
        Action = ["kms:GenerateDataKey*", "kms:Decrypt", "kms:DescribeKey", "kms:CreateGrant"]
        Resource = "*"
      }
    ])
  })

  tags = { Name = "${var.project}-${var.environment}-secrets-cmk", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.project}-${var.environment}-secrets-cmk"
  target_key_id = aws_kms_key.secrets.key_id
}

# ebs-cmk: ECS/EC2 EBS 볼륨 암호화
resource "aws_kms_key" "ebs" {
  description             = "ebs-cmk: ECS on EC2 EBS 볼륨 암호화"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(local.common_key_policy_statements, [
      {
        Sid    = "AllowEC2ServiceUse"
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action = ["kms:GenerateDataKey*", "kms:Decrypt", "kms:DescribeKey", "kms:CreateGrant", "kms:ReEncrypt*"]
        Resource = "*"
      },
      {
        Sid    = "AllowASGUse"
        Effect = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.production_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling" }
        Action = ["kms:GenerateDataKey*", "kms:Decrypt", "kms:DescribeKey", "kms:CreateGrant", "kms:ReEncrypt*"]
        Resource = "*"
      }
    ])
  })

  tags = { Name = "${var.project}-${var.environment}-ebs-cmk", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${var.project}-${var.environment}-ebs-cmk"
  target_key_id = aws_kms_key.ebs.key_id
}
