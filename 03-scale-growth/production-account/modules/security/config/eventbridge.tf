locals {
  immediate_alert_rules = [
    "restricted-ssh",
    "s3-bucket-public-read-prohibited",
    "s3-bucket-public-write-prohibited",
    "iam-root-access-key-check",
    "rds-instance-public-access-check",
    "vpc-flow-logs-enabled",
    "ecs-task-definition-nonroot-user"
  ]
}

resource "aws_cloudwatch_event_rule" "config_compliance_immediate" {
  name        = "${var.project}-${var.environment}-config-noncompliant-critical"
  description = "Triggers SNS for critical Config rule non-compliance"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      messageType                 = ["ComplianceChangeNotification"]
      newEvaluationResult         = { complianceType = ["NON_COMPLIANT"] }
      configRuleName              = local.immediate_alert_rules
    }
  })

  tags = { Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_cloudwatch_event_target" "config_compliance_immediate_sns" {
  rule      = aws_cloudwatch_event_rule.config_compliance_immediate.name
  target_id = "ConfigCriticalToSNS"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      account      = "$.account"
      rule         = "$.detail.configRuleName"
      resource     = "$.detail.resourceId"
      resourceType = "$.detail.resourceType"
      time         = "$.time"
    }
    input_template = "\"[CRITICAL] AWS Config NON_COMPLIANT: Rule=<rule> Resource=<resource> (<resourceType>) Account=<account> Time=<time>\""
  }
}

resource "aws_cloudwatch_log_group" "config_events" {
  name              = "/aws/events/${var.project}-${var.environment}-config-compliance"
  retention_in_days = 90

  tags = { Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_cloudwatch_event_rule" "config_compliance_review" {
  name        = "${var.project}-${var.environment}-config-noncompliant-review"
  description = "All other Config non-compliance events for console review"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      messageType         = ["ComplianceChangeNotification"]
      newEvaluationResult = { complianceType = ["NON_COMPLIANT"] }
    }
  })

  tags = { Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_cloudwatch_event_target" "config_compliance_review_logs" {
  rule      = aws_cloudwatch_event_rule.config_compliance_review.name
  target_id = "ConfigReviewToLogs"
  arn       = aws_cloudwatch_log_group.config_events.arn
}

resource "aws_sns_topic_policy" "config_events" {
  arn = var.sns_topic_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "AllowEventBridgePublish"
      Effect   = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action   = "sns:Publish"
      Resource = var.sns_topic_arn
    }]
  })
}
