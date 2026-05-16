resource "aws_sns_topic" "ops_alerts" {
  name              = "${var.project}-${var.environment}-ops-alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = { Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_sns_topic_subscription" "ops_email" {
  topic_arn = aws_sns_topic.ops_alerts.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}
