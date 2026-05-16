output "log_bucket_arn" {
  value = aws_s3_bucket.logs.arn
}

output "log_bucket_name" {
  value = aws_s3_bucket.logs.id
}

output "log_bucket_domain_name" {
  value = aws_s3_bucket.logs.bucket_domain_name
}
