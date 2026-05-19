##############################################################################
# log_sources
# CloudTrail / WAF Log / DNS Query / VPC Flow Logs / ALB Access Logs
# → Central Logging S3
#
# 추가로 사용된 서비스 (다이어그램에 없음):
#   - Kinesis Data Firehose: WAF는 S3 직접 전송 불가, Firehose 경유 필수
#   - IAM Roles: 각 서비스의 S3 쓰기 권한
#   - CloudWatch Log Group: CloudTrail 실시간 스트리밍 수신
##############################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── CloudTrail ────────────────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.name_prefix}"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_iam_role" "cloudtrail" {
  name = "${var.name_prefix}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "cloudtrail.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "cloudtrail_cw" {
  name = "cloudwatch-logs"
  role = aws_iam_role.cloudtrail.id
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents"], Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*" }]
  })
}

resource "aws_cloudtrail" "this" {
  name                          = "${var.name_prefix}-cloudtrail"
  s3_bucket_name                = var.logging_bucket_id
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
    data_resource {
      type   = "AWS::Lambda::Function"
      values = ["arn:aws:lambda"]
    }
  }

  insight_selector { insight_type = "ApiCallRateInsight" }
  insight_selector { insight_type = "ApiErrorRateInsight" }

  tags = var.tags
}

# ── WAF Logging (Kinesis Firehose 경유) ───────────────────────────────────────
# WAF 자체에는 S3 직접 전송 기능이 없어 Firehose가 중간에 필요합니다.
# Firehose 스트림 이름은 반드시 "aws-waf-logs-" prefix여야 합니다.

resource "aws_iam_role" "waf_firehose" {
  count = var.waf_acl_arn != "" ? 1 : 0
  name  = "${var.name_prefix}-waf-firehose-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "firehose.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "waf_firehose" {
  count = var.waf_acl_arn != "" ? 1 : 0
  name  = "s3-write"
  role  = aws_iam_role.waf_firehose[0].id

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

resource "aws_kinesis_firehose_delivery_stream" "waf" {
  count       = var.waf_acl_arn != "" ? 1 : 0
  name        = "aws-waf-logs-${var.name_prefix}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.waf_firehose[0].arn
    bucket_arn          = var.logging_bucket_arn
    prefix              = "waf-logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "waf-logs-errors/"
    buffering_size      = 64
    buffering_interval  = 300
    compression_format  = "GZIP"
  }

  tags = var.tags
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count                   = var.waf_acl_arn != "" ? 1 : 0
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf[0].arn]
  resource_arn            = var.waf_acl_arn
}

# ── VPC Flow Logs ─────────────────────────────────────────────────────────────

resource "aws_flow_log" "this" {
  for_each = toset(var.vpc_ids)

  vpc_id               = each.value
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = "${var.logging_bucket_arn}/vpc-flow-logs/${each.value}/"

  log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${vpc-id} $${subnet-id} $${instance-id}"

  tags = merge(var.tags, { VpcId = each.value })
}

# ── Route53 DNS Query Logging ─────────────────────────────────────────────────
# CloudWatch Log Group은 반드시 us-east-1이어야 합니다.

resource "aws_cloudwatch_log_group" "dns_query" {
  count             = length(var.route53_zone_ids) > 0 ? 1 : 0
  provider          = aws.us_east_1
  name              = "/aws/route53/${var.name_prefix}"
  retention_in_days = 30
  tags              = var.tags
}

resource "aws_cloudwatch_log_resource_policy" "dns_query" {
  count       = length(var.route53_zone_ids) > 0 ? 1 : 0
  provider    = aws.us_east_1
  policy_name = "${var.name_prefix}-route53-logging"

  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "route53.amazonaws.com" }
      Action    = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource  = "${aws_cloudwatch_log_group.dns_query[0].arn}:*"
    }]
  })
}

resource "aws_route53_query_log" "this" {
  for_each                 = toset(var.route53_zone_ids)
  zone_id                  = each.value
  cloudwatch_log_group_arn = aws_cloudwatch_log_group.dns_query[0].arn
  depends_on               = [aws_cloudwatch_log_resource_policy.dns_query]
}
