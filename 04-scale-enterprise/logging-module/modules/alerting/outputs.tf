output "sns_topic_arn" { value = aws_sns_topic.this.arn }
output "jira_lambda_arn" { value = var.jira_url != "" && var.jira_api_token_secret_arn != "" ? aws_lambda_function.jira[0].arn : "" }
output "slack_lambda_arn" { value = var.slack_webhook_url != "" ? aws_lambda_function.slack[0].arn : "" }
