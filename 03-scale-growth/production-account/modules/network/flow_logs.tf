# ──────────────────────────────────────────
# VPC Flow Logs → Log Archive Account S3
# 커스텀 필드: pkt-srcaddr, pkt-dstaddr 추가
# NAT GW 뿔 ECS Task의 실제 IP 식별 가능
# ──────────────────────────────────────────
resource "aws_flow_log" "main" {
  vpc_id          = aws_vpc.main.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = "${var.log_archive_bucket_arn}/vpc-flow-logs/"

  log_destination_type = "s3"

  # pkt-srcaddr/pkt-dstaddr: NAT GW 뿔 실제 원본 IP 식별
  log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status} $${pkt-srcaddr} $${pkt-dstaddr}"

  tags = { Name = "${var.project}-${var.environment}-flow-logs", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.project}-${var.environment}-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "vpc-flow-logs.amazonaws.com" }
    }]
  })

  tags = { Name = "${var.project}-${var.environment}-flow-logs-role", Project = var.project, Environment = var.environment, ManagedBy = "terraform" }
}

resource "aws_iam_role_policy" "flow_logs" {
  name = "flow-logs-s3-policy"
  role = aws_iam_role.flow_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetBucketAcl"
      ]
      Resource = [
        var.log_archive_bucket_arn,
        "${var.log_archive_bucket_arn}/vpc-flow-logs/*"
      ]
    }]
  })
}
