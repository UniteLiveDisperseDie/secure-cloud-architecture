output "rds_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "rds_address" {
  value = aws_db_instance.main.address
}

output "rds_arn" {
  value = aws_db_instance.main.arn
}

output "rds_id" {
  value = aws_db_instance.main.id
}

output "redis_primary_endpoint" {
  value = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_reader_endpoint" {
  value = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "redis_arn" {
  value = aws_elasticache_replication_group.main.arn
}
