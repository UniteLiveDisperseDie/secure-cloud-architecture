# ──────────────────────────────────────────
# Foundation SCP - 루트 레벨 / 전 계정 공통
# ──────────────────────────────────────────
resource "aws_organizations_policy" "foundation" {
  name        = "Foundation-SCP"
  description = "전 계정 공통 보안 가드레일 (Root 차단, 리전 제한, IAM User 금지 등)"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyRootUser"
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      },
      {
        Sid    = "DenyOutsideAllowedRegions"
        Effect = "Deny"
        NotAction = [
          "iam:*",
          "organizations:*",
          "route53:*",
          "budgets:*",
          "wafv2:*",
          "cloudfront:*",
          "sts:*",
          "support:*",
          "health:*",
          "account:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
        }
      },
      {
        Sid      = "DenyLeaveOrganization"
        Effect   = "Deny"
        Action   = "organizations:LeaveOrganization"
        Resource = "*"
      },
      {
        Sid    = "DenyIAMUserAndAccessKeyCreation"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:CreateAccessKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyS3BucketACLs"
        Effect = "Deny"
        Action = [
          "s3:PutBucketAcl",
          "s3:PutObjectAcl"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = [
              "public-read",
              "public-read-write",
              "authenticated-read"
            ]
          }
        }
      },
      {
        Sid      = "DenyDisableEBSEncryption"
        Effect   = "Deny"
        Action   = "ec2:DisableEbsEncryptionByDefault"
        Resource = "*"
      },
      {
        Sid    = "DenyIAMPasswordPolicyChange"
        Effect = "Deny"
        Action = [
          "iam:DeleteAccountPasswordPolicy",
          "iam:UpdateAccountPasswordPolicy"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyExternalPrincipal"
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalOrgID" = data.aws_organizations_organization.current.id
          }
          Bool = {
            "aws:PrincipalIsAWSService" = "false"
          }
        }
      }
    ]
  })
}

# ──────────────────────────────────────────
# Management OU SCP - Security + Log Archive 계정
# ──────────────────────────────────────────
resource "aws_organizations_policy" "management_ou" {
  name        = "ManagementOU-SCP"
  description = "Security/LogArchive 계정: 워크로드 배포 금지 + 보안 서비스 삭제 금지"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyWorkloadDeployment"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "ecs:CreateCluster",
          "eks:CreateCluster",
          "rds:CreateDBInstance",
          "elasticache:CreateCacheCluster",
          "lambda:CreateFunction"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenySecurityServiceDisable"
        Effect = "Deny"
        Action = [
          "guardduty:DeleteDetector",
          "guardduty:DisassociateFromMasterAccount",
          "guardduty:StopMonitoringMembers",
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail",
          "config:DeleteConfigurationRecorder",
          "config:DeleteDeliveryChannel",
          "config:StopConfigurationRecorder"
        ]
        Resource = "*"
      }
    ]
  })
}

# ──────────────────────────────────────────
# Production OU SCP - Production + Staging 계정
# ──────────────────────────────────────────
resource "aws_organizations_policy" "production_ou" {
  name        = "ProductionOU-SCP"
  description = "Production/Staging: 암호화 강제, 리소스 삭제 제한, IMDSv2 강제, Trail/FlowLogs 보호"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedS3Upload"
        Effect = "Deny"
        Action = "s3:PutObject"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = ["aws:kms", "AES256"]
          }
          Null = {
            "s3:x-amz-server-side-encryption" = "false"
          }
        }
      },
      {
        Sid    = "DenyUnencryptedEBS"
        Effect = "Deny"
        Action = "ec2:CreateVolume"
        Resource = "*"
        Condition = {
          Bool = {
            "ec2:Encrypted" = "false"
          }
        }
      },
      {
        Sid    = "DenyUnauthorizedResourceDeletion"
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances",
          "rds:DeleteDBInstance",
          "dynamodb:DeleteTable"
        ]
        Resource = "*"
        Condition = {
          StringNotLike = {
            "aws:PrincipalARN" = [
              "arn:aws:iam::*:role/ApprovedDestructionRole",
              "arn:aws:iam::*:role/TerraformExecutionRole"
            ]
          }
        }
      },
      {
        Sid    = "DenyIMDSv1"
        Effect = "Deny"
        Action = "ec2:RunInstances"
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringNotEquals = {
            "ec2:MetadataHttpTokens" = "required"
          }
        }
      },
      {
        Sid    = "DenyCloudTrailModification"
        Effect = "Deny"
        Action = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyFlowLogsDeletion"
        Effect = "Deny"
        Action = [
          "ec2:DeleteFlowLogs",
          "logs:DeleteLogGroup",
          "logs:DeleteLogStream"
        ]
        Resource = "*"
      }
    ]
  })
}

# ──────────────────────────────────────────
# Dev OU SCP - Development + Sandbox 계정
# ──────────────────────────────────────────
resource "aws_organizations_policy" "dev_ou" {
  name        = "DevOU-SCP"
  description = "Dev/Sandbox: 비싼 인스턴스 금지, NAT GW 금지, RI 구매 금지, 태깅 강제"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyExpensiveInstances"
        Effect = "Deny"
        Action = "ec2:RunInstances"
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringNotLike = {
            "ec2:InstanceType" = [
              "t2.*", "t3.*", "t3a.*",
              "m5.large", "m5.xlarge",
              "m6i.large", "m6i.xlarge"
            ]
          }
        }
      },
      {
        Sid      = "DenyNATGateway"
        Effect   = "Deny"
        Action   = "ec2:CreateNatGateway"
        Resource = "*"
      },
      {
        Sid    = "DenyReservedInstancePurchase"
        Effect = "Deny"
        Action = [
          "ec2:PurchaseReservedInstancesOffering",
          "savingsplans:CreateSavingsPlan"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyExpensiveServices"
        Effect = "Deny"
        Action = [
          "sagemaker:CreateTrainingJob",
          "sagemaker:CreateHyperParameterTuningJob",
          "elasticmapreduce:RunJobFlow",
          "redshift:CreateCluster"
        ]
        Resource = "*"
      },
      {
        Sid    = "RequireTagsForEC2AndRDS"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "rds:CreateDBInstance"
        ]
        Resource = "*"
        Condition = {
          "Null" = {
            "aws:RequestTag/Environment" = "true"
            "aws:RequestTag/Owner"       = "true"
            "aws:RequestTag/Team"        = "true"
          }
        }
      }
    ]
  })
}
