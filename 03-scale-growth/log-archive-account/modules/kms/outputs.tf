output "s3_log_key_arn" {
  description = "s3-log-cmk KMS Key ARN"
  value       = aws_kms_key.s3_log.arn
}

output "s3_log_key_id" {
  description = "s3-log-cmk KMS Key ID"
  value       = aws_kms_key.s3_log.key_id
}
