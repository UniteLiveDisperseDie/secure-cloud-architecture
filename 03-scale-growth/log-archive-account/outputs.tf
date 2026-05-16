output "log_bucket_arn" {
  description = "중앙 로그 S3 버킷 ARN"
  value       = module.s3.log_bucket_arn
}

output "log_bucket_name" {
  description = "중앙 로그 S3 버킷 이름"
  value       = module.s3.log_bucket_name
}

output "s3_log_key_arn" {
  description = "s3-log-cmk KMS 키 ARN"
  value       = module.kms.s3_log_key_arn
}
