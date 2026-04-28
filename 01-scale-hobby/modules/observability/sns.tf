# SNS Topic
# EventBridge → SNS → Email 알림

resource "aws_sns_topic" "alarm" {
  name = "${var.project}-${var.environment}-alarm"

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-alarm"
  })
}

# EventBridge가 SNS에 Publish할 수 있도록 허용
resource "aws_sns_topic_policy" "alarm" {
  arn = aws_sns_topic.alarm.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowEventBridge"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.alarm.arn
    }]
  })
}

# 이메일 구독
# 최초 apply 후 수신 이메일에서 구독 확인 필요
resource "aws_sns_topic_subscription" "alarm_email" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ── us-east-1 (루트 로그인 알람용) ───────────────
resource "aws_sns_topic" "alarm_global" {
  provider = aws.us_east_1
  name     = "${var.project}-${var.environment}-alarm-global"

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-alarm-global"
  })
}

resource "aws_sns_topic_policy" "alarm_global" {
  provider = aws.us_east_1
  arn      = aws_sns_topic.alarm_global.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowEventBridge"
      Effect = "Allow"
      Principal = {
        Service = "events.amazonaws.com"
      }
      Action   = "SNS:Publish"
      Resource = aws_sns_topic.alarm_global.arn
    }]
  })
}

resource "aws_sns_topic_subscription" "alarm_email_global" {
  provider  = aws.us_east_1
  topic_arn = aws_sns_topic.alarm_global.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
