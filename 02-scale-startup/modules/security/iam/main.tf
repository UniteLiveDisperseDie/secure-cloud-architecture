data "aws_caller_identity" "current" {}

locals {
  name_prefix         = "${var.project}-${var.environment}"
  user_group_name     = "${local.name_prefix}-user-group"
  ec2_role_name       = "${local.name_prefix}-ec2-role"
  admin_role_name     = "${local.name_prefix}-admin-role"
  admin_boundary_name = "${local.name_prefix}-admin-boundary"

  ec2_role_arn       = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.ec2_role_name}"
  admin_role_arn     = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.admin_role_name}"
  admin_boundary_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${local.admin_boundary_name}"
}

# IAM Users
resource "aws_iam_user" "this" {
  for_each = var.users
  name     = each.key
}

resource "aws_iam_group" "users" {
  name = local.user_group_name
}

resource "aws_iam_group_membership" "users" {
  name  = "${local.name_prefix}-user-group-membership"
  users = sort([for user in aws_iam_user.this : user.name])
  group = aws_iam_group.users.name
}

resource "aws_iam_group_policy_attachment" "readonly" {
  group      = aws_iam_group.users.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_group_policy" "assume_admin" {
  name  = "${local.name_prefix}-assume-admin"
  group = aws_iam_group.users.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAssumeAdminRoleWithMFA"
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = local.admin_role_arn
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
        }
      }
    ]
  })
}

resource "aws_iam_group_policy" "enforce_mfa" {
  name  = "${local.name_prefix}-enforce-mfa"
  group = aws_iam_group.users.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyAllIfNoMFAExceptBootstrapActions"
        Effect = "Deny"
        NotAction = [
          "iam:GetUser",
          "iam:ChangePassword",
          "iam:GetAccountPasswordPolicy",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}

# EC2 Role
resource "aws_iam_role" "ec2" {
  name = local.ec2_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2" {
  name = "${local.name_prefix}-ec2-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAppBucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_app_bucket_arn,
          "${var.s3_app_bucket_arn}/*"
        ]
      },
      {
        Sid    = "AllowDbSecretRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          var.secrets_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "app" {
  name = "${local.name_prefix}-app-instance-profile"
  role = aws_iam_role.ec2.name
}

# Admin boundary + role
resource "aws_iam_policy" "admin_boundary" {
  name = local.admin_boundary_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowOnlyArchitectureServices"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "rds:*",
          "cloudwatch:*",
          "logs:*",
          "cloudtrail:*",
          "s3:*",
          "ssm:*",
          "ssmmessages:*",
          "ec2messages:*",
          "cloudfront:*",
          "acm:*",
          "route53:*",
          "sns:*",
          "secretsmanager:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowIamReadOnlyOnly"
        Effect = "Allow"
        Action = [
          "iam:Get*",
          "iam:List*",
          "iam:Generate*",
          "iam:Simulate*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowPassOnlyEc2InstanceRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "iam:GetRole"
        ]
        Resource = local.ec2_role_arn
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ec2.amazonaws.com"
          }
        }
      },
      {
        Sid    = "AllowServiceLinkedRolesForApprovedServices"
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "iam:AWSServiceName" = [
              "autoscaling.amazonaws.com",
              "elasticloadbalancing.amazonaws.com",
              "rds.amazonaws.com",
              "cloudtrail.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid         = "DenyPassRoleOthers"
        Effect      = "Deny"
        Action      = "iam:PassRole"
        NotResource = local.ec2_role_arn
      },
      {
        Sid    = "DenyPrivilegeEscalation"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:CreateRole",
          "iam:DeleteUser",
          "iam:DeleteRole",
          "iam:CreateAccessKey",
          "iam:UpdateAccessKey",
          "iam:DeleteAccessKey",
          "iam:CreateLoginProfile",
          "iam:UpdateLoginProfile",
          "iam:DeleteLoginProfile",
          "iam:AttachUserPolicy",
          "iam:AttachRolePolicy",
          "iam:AttachGroupPolicy",
          "iam:DetachUserPolicy",
          "iam:DetachRolePolicy",
          "iam:DetachGroupPolicy",
          "iam:PutUserPolicy",
          "iam:PutRolePolicy",
          "iam:PutGroupPolicy",
          "iam:DeleteUserPolicy",
          "iam:DeleteRolePolicy",
          "iam:DeleteGroupPolicy",
          "iam:AddUserToGroup",
          "iam:RemoveUserFromGroup",
          "iam:UpdateAssumeRolePolicy"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyBoundaryPolicyTamper"
        Effect = "Deny"
        Action = [
          "iam:CreatePolicyVersion",
          "iam:SetDefaultPolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:DeletePolicy"
        ]
        Resource = local.admin_boundary_arn
      },
      {
        Sid    = "DenyBoundaryAttachmentTamper"
        Effect = "Deny"
        Action = [
          "iam:PutRolePermissionsBoundary",
          "iam:DeleteRolePermissionsBoundary",
          "iam:PutUserPermissionsBoundary",
          "iam:DeleteUserPermissionsBoundary"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyCloudTrailTamper"
        Effect = "Deny"
        Action = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail",
          "cloudtrail:PutEventSelectors",
          "cloudtrail:PutInsightSelectors"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "admin" {
  name                 = local.admin_role_name
  permissions_boundary = aws_iam_policy.admin_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Action = ["sts:AssumeRole"]
      Principal = {
        AWS = [for user in aws_iam_user.this : user.arn]
      }
      Condition = {
        Bool = {
          "aws:MultiFactorAuthPresent" = "true"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
