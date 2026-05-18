##############################################################################
# monitoring
# X-Ray / CloudWatch (Alarms + Dashboard + Metric Filters) / AMP
# → SNS → Slack
#
# 추가로 사용된 서비스 (다이어그램에 없음):
#   - CloudWatch Metric Filters: CloudTrail 로그 → 감지 메트릭 변환
#   - CloudWatch Alarms: 메트릭 임계값 도달 → SNS 트리거
##############################################################################

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ── X-Ray ─────────────────────────────────────────────────────────────────────

resource "aws_xray_group" "this" {
  group_name        = "${var.name_prefix}-default"
  filter_expression = "responsetime > 5"

  insights_configuration {
    insights_enabled      = true
    notifications_enabled = true
  }

  tags = var.tags
}

resource "aws_xray_sampling_rule" "this" {
  rule_name      = "${var.name_prefix}-default"
  priority       = 1000
  version        = 1
  reservoir_size = 5
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"
  tags           = var.tags
}

# ── CloudWatch Metric Filters ─────────────────────────────────────────────────
# CloudTrail 로그에서 보안 이벤트를 메트릭으로 변환합니다.
# 이 메트릭이 CloudWatch Alarms의 기반이 됩니다.

locals {
  security_metric_filters = {
    root-account-usage = {
      pattern    = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
      metric     = "RootAccountUsage"
      threshold  = 1
      alarm_desc = "루트 계정 사용 감지"
    }
    unauthorized-api = {
      pattern    = "{ ($.errorCode = \"*UnauthorizedAccess*\") || ($.errorCode = \"AccessDenied*\") }"
      metric     = "UnauthorizedAttemptCount"
      threshold  = 10
      alarm_desc = "비인가 API 호출 다수 감지"
    }
    iam-policy-changes = {
      pattern    = "{ ($.eventName=DeleteGroupPolicy) || ($.eventName=DeleteRolePolicy) || ($.eventName=DeleteUserPolicy) || ($.eventName=PutGroupPolicy) || ($.eventName=PutRolePolicy) || ($.eventName=PutUserPolicy) || ($.eventName=CreatePolicy) || ($.eventName=DeletePolicy) || ($.eventName=CreatePolicyVersion) || ($.eventName=DeletePolicyVersion) || ($.eventName=SetDefaultPolicyVersion) || ($.eventName=AttachRolePolicy) || ($.eventName=DetachRolePolicy) || ($.eventName=AttachUserPolicy) || ($.eventName=DetachUserPolicy) || ($.eventName=AttachGroupPolicy) || ($.eventName=DetachGroupPolicy) }"
      metric     = "IAMPolicyEventCount"
      threshold  = 1
      alarm_desc = "IAM 정책 변경 감지"
    }
    security-group-changes = {
      pattern    = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"
      metric     = "SecurityGroupEventCount"
      threshold  = 1
      alarm_desc = "보안 그룹 변경 감지"
    }
    cloudtrail-config-changes = {
      pattern    = "{ ($.eventName = CreateTrail) || ($.eventName = UpdateTrail) || ($.eventName = DeleteTrail) || ($.eventName = StartLogging) || ($.eventName = StopLogging) }"
      metric     = "CloudTrailEventCount"
      threshold  = 1
      alarm_desc = "CloudTrail 설정 변경 감지"
    }
    s3-bucket-policy-changes = {
      pattern    = "{ ($.eventSource = s3.amazonaws.com) && (($.eventName = PutBucketAcl) || ($.eventName = PutBucketPolicy) || ($.eventName = PutBucketCors) || ($.eventName = PutBucketLifecycle) || ($.eventName = PutBucketReplication) || ($.eventName = DeleteBucketPolicy) || ($.eventName = DeleteBucketCors) || ($.eventName = DeleteBucketLifecycle) || ($.eventName = DeleteBucketReplication)) }"
      metric     = "S3BucketPolicyEventCount"
      threshold  = 1
      alarm_desc = "S3 버킷 정책 변경 감지"
    }
  }
}

resource "aws_cloudwatch_log_metric_filter" "security" {
  for_each       = local.security_metric_filters
  name           = "${var.name_prefix}-${each.key}"
  log_group_name = var.cloudtrail_log_group
  pattern        = each.value.pattern

  metric_transformation {
    name      = each.value.metric
    namespace = "CloudTrailMetrics/${var.name_prefix}"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "security" {
  for_each = local.security_metric_filters

  alarm_name          = "${var.name_prefix}-${each.key}"
  alarm_description   = each.value.alarm_desc
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = each.value.metric
  namespace           = "CloudTrailMetrics/${var.name_prefix}"
  period              = 300
  statistic           = "Sum"
  threshold           = each.value.threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]
  ok_actions          = [var.sns_topic_arn]

  tags = var.tags
}

# ── CloudWatch Dashboard ──────────────────────────────────────────────────────

resource "aws_cloudwatch_dashboard" "security" {
  dashboard_name = "${var.name_prefix}-security-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x = 0, y = 0, width = 8, height = 6
        properties = {
          title  = "보안 이벤트 요약 (5분)"
          period = 300
          stat   = "Sum"
          view   = "timeSeries"
          metrics = [
            ["CloudTrailMetrics/${var.name_prefix}", "RootAccountUsage", { label = "루트 계정 사용" }],
            ["CloudTrailMetrics/${var.name_prefix}", "UnauthorizedAttemptCount", { label = "비인가 API 호출" }],
            ["CloudTrailMetrics/${var.name_prefix}", "IAMPolicyEventCount", { label = "IAM 정책 변경" }],
            ["CloudTrailMetrics/${var.name_prefix}", "SecurityGroupEventCount", { label = "보안 그룹 변경" }],
          ]
        }
      },
      {
        type = "metric"
        x    = 8, y = 0, width = 8, height = 6
        properties = {
          title  = "GuardDuty Findings"
          period = 3600
          stat   = "Sum"
          view   = "bar"
          metrics = [
            ["AWS/GuardDuty", "FindingCount", "Severity", "HIGH", { label = "HIGH" }],
            ["AWS/GuardDuty", "FindingCount", "Severity", "CRITICAL", { label = "CRITICAL" }],
          ]
        }
      },
      {
        type = "alarm"
        x    = 16, y = 0, width = 8, height = 6
        properties = {
          title  = "활성 알람"
          alarms = [for k, v in aws_cloudwatch_metric_alarm.security : v.arn]
        }
      }
    ]
  })
}

# ── Amazon Managed Prometheus (AMP) ──────────────────────────────────────────

resource "aws_prometheus_workspace" "this" {
  count = var.enable_amp ? 1 : 0
  alias = "${var.name_prefix}-amp"
  tags  = var.tags
}

resource "aws_prometheus_alert_manager_definition" "this" {
  count        = var.enable_amp ? 1 : 0
  workspace_id = aws_prometheus_workspace.this[0].id

  definition = <<-YAML
    alertmanager_config: |
      route:
        receiver: sns
        group_wait: 30s
        group_interval: 5m
        repeat_interval: 1h
      receivers:
        - name: sns
          sns_configs:
            - api_url: https://sns.${data.aws_region.current.name}.amazonaws.com
              topic_arn: ${var.sns_topic_arn}
              subject: "[AMP Alert] {{ .GroupLabels.alertname }}"
              attributes:
                severity: "{{ .CommonLabels.severity }}"
  YAML
}

resource "aws_iam_role" "grafana_amp" {
  count = var.enable_amp && var.grafana_workspace_id != "" ? 1 : 0
  name  = "${var.name_prefix}-grafana-amp-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "grafana.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "grafana_amp" {
  count      = var.enable_amp && var.grafana_workspace_id != "" ? 1 : 0
  role       = aws_iam_role.grafana_amp[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonPrometheusQueryAccess"
}
