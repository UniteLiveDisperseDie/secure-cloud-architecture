resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.project}/${var.environment}/rds/credentials"
  description             = "RDS database credentials"
  kms_key_id              = var.secrets_kms_key_arn
  recovery_window_in_days = 30

  tags = {
    Name        = "${var.project}-${var.environment}-db-secret"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret" "api_key" {
  name                    = "${var.project}/${var.environment}/external/api-key"
  description             = "External API key"
  kms_key_id              = var.secrets_kms_key_arn
  recovery_window_in_days = 30

  tags = {
    Name        = "${var.project}-${var.environment}-api-key"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = jsonencode({ api_key = "REPLACE_ME" })
}
