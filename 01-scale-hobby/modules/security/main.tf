locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ──────────────────────────────────────────
# IAM User
# ──────────────────────────────────────────

resource "aws_iam_user" "this" {
  name = var.iam_user_name

  tags = local.common_tags
}

resource "aws_iam_user_policy_attachment" "admin" {
  user       = aws_iam_user.this.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# MFA 미인증 시 전체 API Deny
resource "aws_iam_user_policy" "mfa_deny" {
  name = "${local.name_prefix}-mfa-deny"
  user = aws_iam_user.this.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Deny"
      Action   = "*"
      Resource = "*"
      Condition = {
        BoolIfExists = {
          "aws:MultiFactorAuthPresent" = "false"
        }
      }
    }]
  })
}

# ──────────────────────────────────────────
# EC2 Instance Role (최소 권한)
# ──────────────────────────────────────────

resource "aws_iam_role" "ec2" {
  name = "${local.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "ec2" {
  name = "${local.name_prefix}-ec2-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_app_bucket_arn,
          "${var.s3_app_bucket_arn}/*"
        ]
      }
    ]
  })
}

# SSM Session Manager 접속
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
  name = "${local.name_prefix}-app-instance-profile"
  role = aws_iam_role.ec2.name
}

# ──────────────────────────────────────────
# GitHub Actions OIDC Provider
# Access Key 없이 OIDC로 AWS 인증
# ──────────────────────────────────────────

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = local.common_tags
}

# ──────────────────────────────────────────
# GitHub Actions Role (최소 권한)
# S3 builds/ 업로드 + SSM Run Command만 허용
# ──────────────────────────────────────────

resource "aws_iam_role" "github_actions" {
  name = "${local.name_prefix}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "github_actions" {
  name = "${local.name_prefix}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3: builds/ 경로에만 업로드 허용
      {
        Sid    = "S3BuildUpload"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${var.s3_app_bucket_arn}/builds/*"
      },
      # SSM: EC2에 Run Command 전달 (Resource 한정)
      {
        Sid    = "SSMRunCommand"
        Effect = "Allow"
        Action = ["ssm:SendCommand"]
        Resource = [
          "arn:aws:ec2:*:*:instance/*",
          "arn:aws:ssm:*:*:document/AWS-RunShellScript"
        ]
      },
      # SSM: 명령 결과 조회 (Resource = * 필요)
      {
        Sid    = "SSMDescribe"
        Effect = "Allow"
        Action = [
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations",
          "ssm:DescribeInstanceInformation"
        ]
        Resource = "*"
      }
    ]
  })
}

# ──────────────────────────────────────────
# S3 App Bucket Policy
# EC2 Role + GitHub Actions Role 허용 + HTTP 전체 Deny
# ──────────────────────────────────────────

resource "aws_s3_bucket_policy" "app" {
  bucket = var.s3_app_bucket_id

  depends_on = [
    aws_iam_role.ec2,
    aws_iam_role.github_actions
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Role"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ec2.arn
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_app_bucket_arn,
          "${var.s3_app_bucket_arn}/*"
        ]
      },
      # GitHub Actions: builds/ 경로에만 업로드 허용
      {
        Sid    = "AllowGithubActionsRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.github_actions.arn
        }
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = "${var.s3_app_bucket_arn}/builds/*"
      },
      {
        Sid       = "DenyNonHttps"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          var.s3_app_bucket_arn,
          "${var.s3_app_bucket_arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
