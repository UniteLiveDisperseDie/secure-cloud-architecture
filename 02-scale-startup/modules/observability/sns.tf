# SNS Topic
# CloudWatch Alarms → SNS → Email notifications

resource "aws_sns_topic" "alarm" {
  name = "${var.project}-${var.environment}-alarm"

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-alarm"
  })
}

# Email subscription
# After first apply, confirm the subscription from the recipient email
resource "aws_sns_topic_subscription" "alarm_email" {
  topic_arn = aws_sns_topic.alarm.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
