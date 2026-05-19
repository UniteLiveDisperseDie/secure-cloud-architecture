output "secret_arn" {
    description = "DB 시크릿 ARN (IAM 정책, EC2 모듈에서 참조)"
    value = aws_secretsmanager_secret.db.arn
}

output "secret_id" {
    description = "DB 시크릿 ID(이름)"
    value = aws_secretsmanager_secret.db.id
}

output "db_password" {
    description = "자동 생성된 DB 비밀번호 (RDS 모듈에 전달)"
    value = random_password.db.result
    sensitive = true
}