# ──────────────────────────────────────────
# IAM Access Analyzer (Organization 신뢰 영역)
# 외부 액세스 분석기만 사용 (미사용 액세스 분석기 X → 무료)
# ──────────────────────────────────────────
resource "aws_accessanalyzer_analyzer" "organization" {
  analyzer_name = "${var.project}-org-analyzer"
  type          = "ORGANIZATION"

  tags = {
    Name      = "${var.project}-org-analyzer"
    Project   = var.project
    ManagedBy = "terraform"
  }
}

# ──────────────────────────────────────────
# EventBridge: ACTIVE Finding 즉시 알림
# ARCHIVED/RESOLVED는 제외
# ──────────────────────────────────────────
resource "aws_cloudwatch_event_rule" "access_analyzer_active" {
  name        = "${var.project}-access-analyzer-active"
  description = "Access Analyzer ACTIVE Finding 즉시 알림 (SCP 우회 시도 가능성)"

  event_pattern = jsonencode({
    source      = ["aws.access-analyzer"]
    detail-type = ["Access Analyzer Finding"]
    detail = {
      status = ["ACTIVE"]
    }
  })
}

resource "aws_cloudwatch_event_target" "access_analyzer_sns" {
  rule      = aws_cloudwatch_event_rule.access_analyzer_active.name
  target_id = "SecuritySNS"
  arn       = var.sns_topic_arn

  input_transformer {
    input_paths = {
      resource_type = "$.detail.resourceType"
      resource      = "$.detail.resource"
      account       = "$.detail.accountId"
      finding_type  = "$.detail.findingType"
    }
    input_template = "\"[Access Analyzer] ACTIVE Finding\nResource Type: <resource_type>\nResource: <resource>\nAccount: <account>\nFinding Type: <finding_type>\n\\n의도된 설정이면 ARCHIVED 처리, 문제이면 RESOLVED 처리 필요\""
  }
}
