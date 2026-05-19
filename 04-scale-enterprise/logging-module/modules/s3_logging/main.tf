##############################################################################
# s3_logging - 중앙 로깅 S3 버킷
# CloudTrail, ELB, VPC Flow Logs, Config, GuardDuty, Firehose 등
# 모든 서비스가 쓸 수 있는 버킷 정책을 미리 설정합니다.
##############################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket" "this" {
  bucket        = "${var.name_prefix}-central-logging"
  force_destroy = false
  tags          = var.tags
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "tiering"
    status = "Enabled"

    filter { prefix = "" }

    transition {
      days          = var.retention_days
      storage_class = "INTELLIGENT_TIERING"
    }

    transition {
      days          = var.glacier_days
      storage_class = "GLACIER_IR"
    }

    expiration {
      # Glacier 이후 3년 만료
      days = var.glacier_days + (365 * 3)
    }
  }

  rule {
    id     = "abort-multipart"
    status = "Enabled"

    filter { prefix = "" }

    abort_incomplete_multipart_upload { days_after_initiation = 7 }
  }
}

# ── 버킷 정책: 모든 로그 소스 허용 ─────────────────────────────────────────

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

data "aws_iam_policy_document" "bucket" {

  # 강제 HTTPS
  statement {
    sid    = "DenyHTTP"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  # CloudTrail
  statement {
    sid    = "CloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.this.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "CloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/cloudtrail/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  # ELB Access Logs (ap-northeast-2 ELB service account)
  statement {
    sid    = "ELBAccessLogs"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::600734575887:root"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/alb-access-logs/*"]
  }

  # VPC Flow Logs
  statement {
    sid    = "VPCFlowLogsAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
    resources = [aws_s3_bucket.this.arn]
  }

  statement {
    sid    = "VPCFlowLogsWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/vpc-flow-logs/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  # AWS Config
  statement {
    sid    = "ConfigWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl", "s3:PutObject"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/config/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # GuardDuty Findings Export
  statement {
    sid    = "GuardDutyWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/guardduty/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # Kinesis Firehose (WAF 로그, 온프레미스 FluentBit, AppFabric 공통)
  statement {
    sid    = "FirehoseWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
    actions = ["s3:AbortMultipartUpload", "s3:GetBucketLocation", "s3:GetObject",
    "s3:ListBucket", "s3:ListBucketMultipartUploads", "s3:PutObject"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # AppFabric
  statement {
    sid    = "AppFabricWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["appfabric.amazonaws.com"]
    }
    actions   = ["s3:PutObject", "s3:PutObjectAcl"]
    resources = ["${aws_s3_bucket.this.arn}/saas-appfabric/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}
