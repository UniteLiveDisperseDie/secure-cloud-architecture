# EC2 인스턴스 (App + DB 동거)
resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = local.instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.sg_ec2_id]
  iam_instance_profile   = var.iam_instance_profile_name

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 필수
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = false # DB 데이터 보호 — 인스턴스 삭제 시에도 볼륨 유지
    encrypted             = true
  }

  user_data_base64 = filebase64("${path.module}/scripts/install.sh")

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-app-server"
  })
}
