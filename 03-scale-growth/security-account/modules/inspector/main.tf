# ──────────────────────────────────────────
# Inspector v2 (Security Account 위임 관리자)
# EC2 OS CVE + ECR 이미지 CVE 지속 스캔
# ──────────────────────────────────────────
resource "aws_inspector2_enabler" "main" {
  # Security Account에서 위임 관리자로 서비스 활성화
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2", "ECR", "LAMBDA"]
}

data "aws_caller_identity" "current" {}

# 조직 수준 자동 활성화 (member accounts)
resource "aws_inspector2_organization_configuration" "main" {
  auto_enable {
    ec2    = true
    ecr    = true
    lambda = false
  }
}
