output "cloudtrail_arn" { value = aws_cloudtrail.this.arn }
output "cloudtrail_log_group_name" { value = aws_cloudwatch_log_group.cloudtrail.name }
output "waf_firehose_arn" { value = var.waf_acl_arn != "" ? aws_kinesis_firehose_delivery_stream.waf[0].arn : "" }
output "vpc_flow_log_ids" { value = { for k, v in aws_flow_log.this : k => v.id } }
