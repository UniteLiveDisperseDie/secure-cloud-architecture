locals {
  security_ns      = "${var.project}/SecurityMetrics"
  alb_arn_suffix   = join("/", slice(split("/", var.alb_arn), 1, 4))
  ecs_service_name = "${var.project}-${var.environment}-app"
  rds_instance_id  = "${var.project}-${var.environment}-rds"
  waf_web_acl_name = "${var.project}-cloudfront-waf"
}

resource "aws_cloudwatch_log_metric_filter" "root_login" {
  name           = "${var.project}-RootUserLogin"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  metric_transformation {
    name      = "RootUserLoginCount"
    namespace = local.security_ns
    value     = "1"
    unit      = "Count"
  }
}
resource "aws_cloudwatch_metric_alarm" "root_login" {
  alarm_name          = "${var.project}-RootUserLogin"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootUserLoginCount"
  namespace           = local.security_ns
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Root user login detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "mfa_less_login" {
  name           = "${var.project}-MFAlessConsoleLogin"
  pattern        = "{ $.eventName = \"ConsoleLogin\" && $.additionalEventData.MFAUsed != \"Yes\" && $.userIdentity.type != \"AssumedRole\" }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  metric_transformation {
    name      = "MFAlessConsoleLoginCount"
    namespace = local.security_ns
    value     = "1"
    unit      = "Count"
  }
}
resource "aws_cloudwatch_metric_alarm" "mfa_less_login" {
  alarm_name          = "${var.project}-MFAlessConsoleLogin"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "MFAlessConsoleLoginCount"
  namespace           = local.security_ns
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Console login without MFA detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "${var.project}-UnauthorizedAPICalls"
  pattern        = "{ ($.errorCode = \"*UnauthorizedAccess*\") || ($.errorCode = \"AccessDenied\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  metric_transformation {
    name      = "UnauthorizedAPICallCount"
    namespace = local.security_ns
    value     = "1"
    unit      = "Count"
  }
}
resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "${var.project}-UnauthorizedAPICalls"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnauthorizedAPICallCount"
  namespace           = local.security_ns
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Multiple unauthorized API calls detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "iam_changes" {
  name           = "${var.project}-IAMChanges"
  pattern        = "{ ($.eventSource = \"iam.amazonaws.com\") && (($.eventName = \"CreateUser\") || ($.eventName = \"CreateAccessKey\") || ($.eventName = \"AttachRolePolicy\") || ($.eventName = \"PutRolePolicy\") || ($.eventName = \"CreatePolicy\") || ($.eventName = \"DeletePolicy\")) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  metric_transformation {
    name      = "IAMChangesCount"
    namespace = local.security_ns
    value     = "1"
    unit      = "Count"
  }
}
resource "aws_cloudwatch_metric_alarm" "iam_changes" {
  alarm_name          = "${var.project}-IAMChanges"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "IAMChangesCount"
  namespace           = local.security_ns
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "IAM changes detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "sg_changes" {
  name           = "${var.project}-SGChanges"
  pattern        = "{ ($.eventName = \"AuthorizeSecurityGroupIngress\") || ($.eventName = \"RevokeSecurityGroupIngress\") || ($.eventName = \"CreateSecurityGroup\") || ($.eventName = \"DeleteSecurityGroup\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  metric_transformation {
    name      = "SGChangesCount"
    namespace = local.security_ns
    value     = "1"
    unit      = "Count"
  }
}
resource "aws_cloudwatch_metric_alarm" "sg_changes" {
  alarm_name          = "${var.project}-SecurityGroupChanges"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "SGChangesCount"
  namespace           = local.security_ns
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Security group changes detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "cloudtrail_stopped" {
  name           = "${var.project}-CloudTrailStopped"
  pattern        = "{ ($.eventName = \"StopLogging\") || ($.eventName = \"DeleteTrail\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  metric_transformation {
    name      = "CloudTrailStoppedCount"
    namespace = local.security_ns
    value     = "1"
    unit      = "Count"
  }
}
resource "aws_cloudwatch_metric_alarm" "cloudtrail_stopped" {
  alarm_name          = "${var.project}-CloudTrailStopped"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CloudTrailStoppedCount"
  namespace           = local.security_ns
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "CloudTrail stopped or modified"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "guardduty_disabled" {
  name           = "${var.project}-GuardDutyDisabled"
  pattern        = "{ ($.eventSource = \"guardduty.amazonaws.com\") && ($.eventName = \"DeleteDetector\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  metric_transformation {
    name      = "GuardDutyDisabledCount"
    namespace = local.security_ns
    value     = "1"
    unit      = "Count"
  }
}
resource "aws_cloudwatch_metric_alarm" "guardduty_disabled" {
  alarm_name          = "${var.project}-GuardDutyDisabled"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "GuardDutyDisabledCount"
  namespace           = local.security_ns
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "GuardDuty disabled"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "s3_policy_changes" {
  name           = "${var.project}-S3PolicyChanges"
  pattern        = "{ ($.eventSource = \"s3.amazonaws.com\") && (($.eventName = \"PutBucketAcl\") || ($.eventName = \"PutBucketPolicy\") || ($.eventName = \"DeleteBucketPolicy\")) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  metric_transformation {
    name      = "S3PolicyChangesCount"
    namespace = local.security_ns
    value     = "1"
    unit      = "Count"
  }
}
resource "aws_cloudwatch_metric_alarm" "s3_policy_changes" {
  alarm_name          = "${var.project}-S3PolicyChanges"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "S3PolicyChangesCount"
  namespace           = local.security_ns
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "S3 policy changes detected"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "kms_key_deletion" {
  name           = "${var.project}-KMSKeyDeletion"
  pattern        = "{ ($.eventSource = \"kms.amazonaws.com\") && (($.eventName = \"DisableKey\") || ($.eventName = \"ScheduleKeyDeletion\")) }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  metric_transformation {
    name      = "KMSKeyDeletionCount"
    namespace = local.security_ns
    value     = "1"
    unit      = "Count"
  }
}
resource "aws_cloudwatch_metric_alarm" "kms_key_deletion" {
  alarm_name          = "${var.project}-KMSKeyDeletion"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "KMSKeyDeletionCount"
  namespace           = local.security_ns
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "KMS key disabled or scheduled for deletion"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_log_metric_filter" "organizations_leave" {
  name           = "${var.project}-OrganizationsLeave"
  pattern        = "{ ($.eventSource = \"organizations.amazonaws.com\") && ($.eventName = \"LeaveOrganization\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  metric_transformation {
    name      = "OrganizationsLeaveCount"
    namespace = local.security_ns
    value     = "1"
    unit      = "Count"
  }
}
resource "aws_cloudwatch_metric_alarm" "organizations_leave" {
  alarm_name          = "${var.project}-OrganizationsLeave"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "OrganizationsLeaveCount"
  namespace           = local.security_ns
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Attempt to leave AWS Organizations"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
}

# Service metric alarms
resource "aws_cloudwatch_metric_alarm" "alb_4xx" {
  alarm_name          = "${var.project}-ALB-4XXErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_4XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "ALB 4XX > 100 in 5 minutes"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
  dimensions          = { LoadBalancer = local.alb_arn_suffix }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project}-ALB-5XXErrors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 20
  alarm_description   = "ALB 5XX > 20 in 5 minutes"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
  dimensions          = { LoadBalancer = local.alb_arn_suffix }
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name          = "${var.project}-ECS-HighCPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS CPU > 80%"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
  dimensions          = { ClusterName = var.ecs_cluster_name, ServiceName = local.ecs_service_name }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.project}-RDS-HighCPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "RDS CPU > 90%"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
  dimensions          = { DBInstanceIdentifier = local.rds_instance_id }
}

resource "aws_cloudwatch_metric_alarm" "waf_blocked" {
  alarm_name          = "${var.project}-WAF-HighBlocked"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300
  statistic           = "Sum"
  threshold           = 1000
  alarm_description   = "WAF blocked > 1000 requests in 5 minutes"
  alarm_actions       = [aws_sns_topic.ops_alerts.arn]
  treat_missing_data  = "notBreaching"
  dimensions          = { WebACL = local.waf_web_acl_name, Region = "us-east-1", Rule = "ALL" }
}
