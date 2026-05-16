output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_credentials.arn
}

output "db_secret_id" {
  value = aws_secretsmanager_secret.db_credentials.id
}

output "api_key_secret_arn" {
  value = aws_secretsmanager_secret.api_key.arn
}
