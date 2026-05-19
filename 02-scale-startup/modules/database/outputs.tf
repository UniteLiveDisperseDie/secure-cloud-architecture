output "rds_endpoint" {
  description = "RDS 인스턴스 엔드포인트"
  value       = aws_db_instance.mysql.endpoint
}

output "rds_identifier" {
  description = "RDS 인스턴스 식별자"
  value       = aws_db_instance.mysql.identifier
}
