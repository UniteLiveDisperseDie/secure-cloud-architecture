terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

locals {
  name_prefix = "${var.project}-${var.environment}"
}

# DB 접속 정보

resource "aws_secretsmanager_secret" "db" {
  # kms_key_id를 지정하지 않으면 Secrets Manager의 AWS managed key
  # (aws/secretsmanager)로 암호화된다.
  name                    = "${local.name_prefix}/db/credentials"
  description             = "RDS DB 접속 정보"
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name        = "${local.name_prefix}-db-secret"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    dbname   = var.db_name
    host     = ""
    port     = 3306
  })
}

resource "random_password" "db" {
  length           = 16
  special          = true
  override_special = "!#$%^&*()-_=+[]{}|;:,.<>?"
}
