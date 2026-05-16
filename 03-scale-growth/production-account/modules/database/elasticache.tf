resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project}-${var.environment}-redis-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_elasticache_parameter_group" "redis7" {
  name   = "${var.project}-${var.environment}-redis7"
  family = "redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project}-${var.environment}-redis"
  description          = "Redis cluster for ${var.project}-${var.environment}"

  node_type          = var.cache_node_type
  num_cache_clusters = 2
  port               = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [var.cache_security_group_id]

  parameter_group_name = aws_elasticache_parameter_group.redis7.name

  at_rest_encryption_enabled = true
  kms_key_id                 = var.rds_kms_key_arn
  transit_encryption_enabled = true
  auth_token                 = var.cache_auth_token
  transit_encryption_mode    = "required"

  automatic_failover_enabled = true
  multi_az_enabled           = true

  engine_version = "7.0"

  snapshot_retention_limit = 7
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "mon:05:00-mon:07:00"

  apply_immediately = false

  tags = {
    Name        = "${var.project}-${var.environment}-redis"
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
