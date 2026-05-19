resource "aws_guardduty_detector" "main" {
  enable = true

  tags = {
    Name      = "${var.project}-guardduty"
    Project   = var.project
    ManagedBy = "terraform"
  }
}

resource "aws_guardduty_detector_feature" "s3_data_events" {
  detector_id = aws_guardduty_detector.main.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "ebs_malware_protection" {
  detector_id = aws_guardduty_detector.main.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = "ENABLED"
}

resource "aws_guardduty_organization_configuration" "main" {
  auto_enable_organization_members = "ALL"
  detector_id                      = aws_guardduty_detector.main.id
}

resource "aws_guardduty_organization_configuration_feature" "s3_data_events" {
  detector_id = aws_guardduty_detector.main.id
  name        = "S3_DATA_EVENTS"
  auto_enable = "ALL"
}

resource "aws_guardduty_organization_configuration_feature" "ebs_malware_protection" {
  detector_id = aws_guardduty_detector.main.id
  name        = "EBS_MALWARE_PROTECTION"
  auto_enable = "ALL"
}

resource "aws_cloudwatch_event_rule" "guardduty_high_critical" {
  name        = "${var.project}-guardduty-high-critical"
  description = "GuardDuty severity >= 7.0 즉시 알림"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      severity = [{ numeric = [">=", 7.0] }]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_high_critical_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_high_critical.name
  target_id = "SecuritySNS"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      severity   = "$.detail.severity"
      type       = "$.detail.type"
      account    = "$.detail.accountId"
      region     = "$.region"
      finding_id = "$.detail.id"
    }
    input_template = "\"[HIGH/CRITICAL] GuardDuty Finding\\nSeverity: <severity>\\nType: <type>\\nAccount: <account>\\nRegion: <region>\\nFinding ID: <finding_id>\""
  }
}

resource "aws_cloudwatch_event_rule" "guardduty_critical_types" {
  name        = "${var.project}-guardduty-critical-types"
  description = "CryptoCurrency / InstanceCredentialExfiltration 즉시 알림"

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]
    detail = {
      type = [
        { prefix = "CryptoCurrency" },
        { prefix = "UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration" }
      ]
    }
  })
}

resource "aws_cloudwatch_event_target" "guardduty_critical_types_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_critical_types.name
  target_id = "SecuritySNS"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      type    = "$.detail.type"
      account = "$.detail.accountId"
    }
    input_template = "\"[CRITICAL] GuardDuty 위협 탐지: <type> (Account: <account>). 즉시 대응 필요\""
  }
}

resource "aws_sns_topic_policy" "security_alerts" {
  arn = var.sns_topic_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowEventBridgePublish"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = var.sns_topic_arn
    }]
  })
}
