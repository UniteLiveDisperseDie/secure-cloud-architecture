##############################################################################
# onprem_integration
# IDC Servers + FluentBit → Kinesis Data Firehose → Central Logging S3
#
# existing_iam_role_arn이 있는 소스: IAM User + Access Key를 생성하지 않습니다.
#   온프레미스 서버에서 AssumeRole 또는 EC2 Instance Profile로 인증하세요.
# existing_iam_role_arn이 없는 소스: IAM User + Access Key를 자동 생성하고
#   Secrets Manager에 FluentBit 설정과 함께 저장합니다.
##############################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # IAM User가 필요한 소스(existing_iam_role_arn이 없는 것)만 필터링
  sources_needing_iam_user = {
    for s in var.onprem_sources : s.name => s
    if s.existing_iam_role_arn == ""
  }
  # 기존 Role을 쓰는 소스
  sources_with_existing_role = {
    for s in var.onprem_sources : s.name => s
    if s.existing_iam_role_arn != ""
  }
  # 전체 소스 맵
  all_sources = { for s in var.onprem_sources : s.name => s }
}

# ── Firehose IAM Role (소스별, 항상 생성) ────────────────────────────────────

resource "aws_iam_role" "firehose" {
  for_each = local.all_sources
  name     = "${var.name_prefix}-onprem-firehose-${each.key}"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ 
      Effect = "Allow",
      Principal = { Service = "firehose.amazonaws.com" }, 
      Action = "sts:AssumeRole" }]
  })
  tags = merge(var.tags, { OnpremSource = each.key })
}

resource "aws_iam_role_policy" "firehose_s3" {
  for_each = local.all_sources
  name     = "s3-write"
  role     = aws_iam_role.firehose[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["s3:AbortMultipartUpload", "s3:GetBucketLocation", "s3:GetObject",
      "s3:ListBucket", "s3:ListBucketMultipartUploads", "s3:PutObject"]
      Resource = [var.logging_bucket_arn, "${var.logging_bucket_arn}/*"]
    }]
  })
}

# ── Kinesis Firehose Delivery Stream (소스별) ────────────────────────────────

resource "aws_kinesis_firehose_delivery_stream" "this" {
  for_each    = local.all_sources
  name        = "${var.name_prefix}-onprem-${each.key}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose[each.key].arn
    bucket_arn          = var.logging_bucket_arn
    prefix              = "${each.value.log_prefix}year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "${each.value.log_prefix}errors/"
    buffering_size      = 64
    buffering_interval  = 300
    compression_format  = "GZIP"
  }

  tags = merge(var.tags, { OnpremSource = each.key })
}

resource "aws_cloudwatch_log_group" "firehose" {
  for_each          = local.all_sources
  name              = "/aws/kinesisfirehose/${var.name_prefix}-onprem-${each.key}"
  retention_in_days = var.log_retention_days
  tags              = merge(var.tags, { OnpremSource = each.key })
}

# ── IAM User + Access Key (existing_iam_role_arn이 없는 소스만) ─────────────

resource "aws_iam_user" "fluentbit" {
  for_each = local.sources_needing_iam_user
  name     = "${var.name_prefix}-fluentbit-${each.key}"
  tags     = merge(var.tags, { OnpremSource = each.key })
}

resource "aws_iam_user_policy" "fluentbit" {
  for_each = local.sources_needing_iam_user
  name     = "firehose-put"
  user     = aws_iam_user.fluentbit[each.key].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["firehose:PutRecord", "firehose:PutRecordBatch"]
      Resource = aws_kinesis_firehose_delivery_stream.this[each.key].arn
    }]
  })
}

resource "aws_iam_access_key" "fluentbit" {
  for_each = local.sources_needing_iam_user
  user     = aws_iam_user.fluentbit[each.key].name
}

# ── Secrets Manager: FluentBit 설정 저장 ────────────────────────────────────
# IAM User를 생성한 소스: Access Key + FluentBit OUTPUT 설정 저장
# 기존 Role을 쓰는 소스: FluentBit OUTPUT 설정만 저장 (자격증명 없음)

resource "aws_secretsmanager_secret" "fluentbit" {
  for_each = local.all_sources
  name     = "${var.name_prefix}/onprem/${each.key}/fluentbit"
  tags     = merge(var.tags, { OnpremSource = each.key })
}

resource "aws_secretsmanager_secret_version" "fluentbit_with_key" {
  for_each  = local.sources_needing_iam_user
  secret_id = aws_secretsmanager_secret.fluentbit[each.key].id

  secret_string = jsonencode({
    auth_method             = "iam_user"
    aws_access_key_id       = aws_iam_access_key.fluentbit[each.key].id
    aws_secret_access_key   = aws_iam_access_key.fluentbit[each.key].secret
    aws_region              = data.aws_region.current.name
    firehose_stream_name    = aws_kinesis_firehose_delivery_stream.this[each.key].name
    fluentbit_output_config = <<-CONF
      [OUTPUT]
          Name              kinesis_firehose
          Match             *
          region            ${data.aws_region.current.name}
          delivery_stream   ${aws_kinesis_firehose_delivery_stream.this[each.key].name}
          time_key          time
          time_key_format   %Y-%m-%dT%H:%M:%S
    CONF
  })
}

resource "aws_secretsmanager_secret_version" "fluentbit_with_role" {
  for_each  = local.sources_with_existing_role
  secret_id = aws_secretsmanager_secret.fluentbit[each.key].id

  secret_string = jsonencode({
    auth_method             = "iam_role"
    iam_role_arn            = each.value.existing_iam_role_arn
    aws_region              = data.aws_region.current.name
    firehose_stream_name    = aws_kinesis_firehose_delivery_stream.this[each.key].name
    note                    = "IAM Role을 사용합니다. EC2 Instance Profile 또는 AssumeRole로 인증하세요."
    fluentbit_output_config = <<-CONF
      [OUTPUT]
          Name              kinesis_firehose
          Match             *
          region            ${data.aws_region.current.name}
          delivery_stream   ${aws_kinesis_firehose_delivery_stream.this[each.key].name}
          time_key          time
          time_key_format   %Y-%m-%dT%H:%M:%S
    CONF
  })
}
