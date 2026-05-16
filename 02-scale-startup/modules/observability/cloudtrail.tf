# CloudWatch Log Group
# Send CloudTrail logs to CloudWatch Logs
# Source for metric filter-based alarms

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project}-${var.environment}"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(local.common_tags, {
    Name = "/aws/cloudtrail/${var.project}-${var.environment}"
  })
}

# IAM Role for CloudTrail to send logs to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "${var.project}-${var.environment}-cloudtrail-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "${var.project}-${var.environment}-cloudtrail-cw-policy"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# CloudTrail
# Record only management events (exclude data events)

resource "aws_cloudtrail" "main" {
  name                          = "${var.project}-${var.environment}-trail"
  s3_bucket_name                = var.s3_log_bucket_name
  s3_key_prefix                 = "cloudtrail"
  include_global_service_events = true  # Include global services like IAM
  is_multi_region_trail         = true  # Capture global/IAM events more reliably
  enable_log_file_validation    = true  # Enable log file integrity validation

  # Integrate with CloudWatch Logs (required for metric-filter-based alarms)
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch.arn

  # Record only management events
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_cloudwatch_log_group.cloudtrail]

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-trail"
  })
}
