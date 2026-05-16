resource "random_password" "db" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.db_secret_id

  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db.result
    port     = 3306
    engine   = var.db_engine
    dbname   = "appdb"
  })
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-${var.environment}-rds-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name        = "${var.project}-${var.environment}-rds-subnet-group"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_db_parameter_group" "main" {
  name   = "${var.project}-${var.environment}-mysql8"
  family = "mysql8.0"

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "2"
  }

  parameter {
    name  = "log_output"
    value = "FILE"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_db_instance" "main" {
  identifier = "${var.project}-${var.environment}-rds"

  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 5
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.rds_kms_key_arn

  db_name  = "appdb"
  username = "dbadmin"
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  parameter_group_name   = aws_db_parameter_group.main.name

  multi_az               = true
  publicly_accessible    = false
  deletion_protection    = true
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.project}-${var.environment}-rds-final"

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = var.rds_kms_key_arn
  performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  depends_on = [aws_secretsmanager_secret_version.db_credentials]

  tags = {
    Name        = "${var.project}-${var.environment}-rds"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
