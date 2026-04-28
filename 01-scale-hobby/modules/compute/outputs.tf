# EC2
output "ec2_instance_id" {
  description = "EC2 인스턴스 ID (networking 모듈 ALB Target Group 연결에 사용)"
  value       = aws_instance.app.id
}
