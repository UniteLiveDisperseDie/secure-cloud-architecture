##############################################################################
# opensearch_siem
# Logging S3 → OSIS Pipeline → OpenSearch → Detection → Jira (Lambda)
#
# 추가로 사용된 서비스 (다이어그램에 없음):
#   - OSIS (OpenSearch Ingestion Service): S3 → OpenSearch 자동 파이프라인
#   - Secrets Manager: admin 비밀번호 저장
#   - Security Group: VPC 내 OpenSearch 접근 제어
#   - Random: admin 비밀번호 생성
##############################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_vpc" "this" { id = var.vpc_id }

locals {
  # Security Group: 사용자가 제공했으면 그걸 쓰고, 없으면 자동 생성한 것 사용
  use_existing_sg    = length(var.security_group_ids) > 0
  security_group_ids = local.use_existing_sg ? var.security_group_ids : [aws_security_group.opensearch[0].id]

  # 비밀번호: 사용자가 Secret ARN을 제공했으면 그걸 쓰고, 없으면 자동 생성
  use_existing_secret = var.admin_secret_arn != ""
  admin_secret_arn    = local.use_existing_secret ? var.admin_secret_arn : aws_secretsmanager_secret.admin[0].arn
  admin_password = local.use_existing_secret ? (
    jsondecode(data.aws_secretsmanager_secret_version.existing_admin[0].secret_string)["password"]
  ) : random_password.admin[0].result
}

# ── Security Group (사용자가 제공하지 않은 경우에만 생성) ─────────────────────

resource "aws_security_group" "opensearch" {
  count       = local.use_existing_sg ? 0 : 1
  name        = "${var.name_prefix}-opensearch-sg"
  description = "OpenSearch SIEM - VPC CIDR에서 443만 허용. 기존 SG를 쓰려면 security_group_ids를 입력하세요."
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# ── Admin 자격증명 (사용자가 Secret ARN을 제공하지 않은 경우에만 생성) ──────────

# 기존 Secret 참조 (admin_secret_arn이 제공된 경우)
data "aws_secretsmanager_secret_version" "existing_admin" {
  count     = local.use_existing_secret ? 1 : 0
  secret_id = var.admin_secret_arn
}

# 자동 생성 (admin_secret_arn이 비어있는 경우)
resource "random_password" "admin" {
  count            = local.use_existing_secret ? 0 : 1
  length           = 20
  special          = true
  override_special = "!#$%&()-_=+[]<>:"
}

resource "aws_secretsmanager_secret" "admin" {
  count = local.use_existing_secret ? 0 : 1
  name  = "${var.name_prefix}/opensearch/admin"
  tags  = var.tags
}

resource "aws_secretsmanager_secret_version" "admin" {
  count     = local.use_existing_secret ? 0 : 1
  secret_id = aws_secretsmanager_secret.admin[0].id
  secret_string = jsonencode({
    username      = "admin"
    password      = random_password.admin[0].result
    endpoint      = "https://${aws_opensearch_domain.this.endpoint}"
    dashboard_url = "https://${aws_opensearch_domain.this.endpoint}/_dashboards"
  })
}

# ── CloudWatch Log Groups ────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "opensearch" {
  for_each          = toset(["index-slow", "search-slow", "application"])
  name              = "/aws/opensearch/${var.name_prefix}/${each.key}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_resource_policy" "opensearch" {
  policy_name = "${var.name_prefix}-opensearch-logs"
  policy_document = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "es.amazonaws.com" }
      Action    = ["logs:PutLogEvents", "logs:CreateLogStream"]
      Resource  = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/opensearch/${var.name_prefix}/*"
    }]
  })
}

# ── OpenSearch Domain ─────────────────────────────────────────────────────────

resource "aws_opensearch_domain" "this" {
  domain_name    = "${var.name_prefix}-siem"
  engine_version = "OpenSearch_2.13"

  cluster_config {
    instance_type          = var.instance_type
    instance_count         = var.instance_count
    zone_awareness_enabled = var.instance_count > 1

    dynamic "zone_awareness_config" {
      for_each = var.instance_count > 1 ? [1] : []
      content { availability_zone_count = min(var.instance_count, 3) }
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.ebs_volume_size
    volume_type = "gp3"
  }

  encrypt_at_rest { enabled = true }
  node_to_node_encryption { enabled = true }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-PFS-2023-10"
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    internal_user_database_enabled = true
    master_user_options {
      master_user_name     = "admin"
      master_user_password = local.admin_password
    }
  }

  vpc_options {
    subnet_ids         = var.subnet_ids
    security_group_ids = local.security_group_ids
  }

  log_publishing_options {
    log_type                 = "INDEX_SLOW_LOGS"
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch["index-slow"].arn
  }
  log_publishing_options {
    log_type                 = "SEARCH_SLOW_LOGS"
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch["search-slow"].arn
  }
  log_publishing_options {
    log_type                 = "ES_APPLICATION_LOGS"
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch["application"].arn
  }

  tags       = var.tags
  depends_on = [aws_cloudwatch_log_resource_policy.opensearch]
}

resource "aws_opensearch_domain_policy" "this" {
  domain_name = aws_opensearch_domain.this.domain_name
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.osis.arn }
        Action    = ["es:ESHttp*"]
        Resource  = "${aws_opensearch_domain.this.arn}/*"
      },
      {
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = ["es:*"]
        Resource  = "${aws_opensearch_domain.this.arn}/*"
      }
    ]
  })
}

# ── OSIS Pipeline: S3 → OpenSearch ───────────────────────────────────────────

resource "aws_iam_role" "osis" {
  name = "${var.name_prefix}-osis-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ 
      Effect = "Allow", 
      Principal = { Service = "osis-pipelines.amazonaws.com" }, 
      Action = "sts:AssumeRole" }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "osis" {
  name = "s3-read-opensearch-write"
  role = aws_iam_role.osis.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = [var.logging_bucket_arn, "${var.logging_bucket_arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["es:ESHttp*"]
        Resource = "${aws_opensearch_domain.this.arn}/*"
      }
    ]
  })
}

resource "aws_osis_pipeline" "this" {
  pipeline_name = "${var.name_prefix}-s3-to-siem"
  min_units     = 1
  max_units     = 4

  pipeline_configuration_body = <<-YAML
    version: "2"
    s3-log-pipeline:
      source:
        s3:
          codec:
            newline: {}
          aws:
            region: ${data.aws_region.current.name}
            sts_role_arn: ${aws_iam_role.osis.arn}
          scan:
            buckets:
              - bucket:
                  name: ${var.logging_bucket_id}
                  filter:
                    include_prefix:
                      - "cloudtrail/"
                      - "guardduty/"
                      - "vpc-flow-logs/"
                      - "waf-logs/"
                      - "config/"
                      - "saas-appfabric/"
                      - "onprem/"
            scheduling:
              interval: PT5M
      processor:
        - date:
            from_time_received: true
            destination: "@timestamp"
      sink:
        - opensearch:
            hosts: ["https://${aws_opensearch_domain.this.endpoint}"]
            index: "logs-%%{yyyy.MM.dd}"
            aws:
              region: ${data.aws_region.current.name}
              sts_role_arn: ${aws_iam_role.osis.arn}
  YAML

  tags = var.tags
}
