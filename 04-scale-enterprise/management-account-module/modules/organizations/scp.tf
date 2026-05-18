# ─── Foundation SCP (Root 레벨 / 전 계정 공통) ───────────────────────────────
resource "aws_organizations_policy" "foundation" {
  name        = "Foundation-SCP"
  description = "전 계정 공통 보안 가드레일: Root 차단, 리전 제한, CloudTrail 보호, IAM User 금지 등"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyRootUser"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringLike = { "aws:PrincipalArn" = "arn:aws:iam::*:root" }
        }
      },
      {
        Sid    = "DenyOutsideAllowedRegions"
        Effect = "Deny"
        NotAction = [
          "iam:*", "organizations:*", "route53:*", "budgets:*",
          "wafv2:*", "cloudfront:*", "sts:*", "support:*",
          "health:*", "account:*", "billing:*", "ce:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = { "aws:RequestedRegion" = var.allowed_regions }
        }
      },
      {
        Sid    = "DenyCloudTrailTampering"
        Effect = "Deny"
        Action = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail",
          "cloudtrail:PutEventSelectors"
        ]
        Resource = "*"
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
        Action = ["iam:CreateUser", "iam:CreateAccessKey"]
        Resource = "*"
      },
      {
        # S3 ACL 활성화 버킷 차단 → BucketOwnerEnforced 강제
        Sid    = "EnforceS3BucketOwnerEnforced"
        Effect = "Deny"
        Action = "s3:PutBucketOwnershipControls"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-object-ownership" = "BucketOwnerEnforced"
          }
        }
      },
      {
        # S3 퍼블릭 ACL 차단
        Sid    = "DenyS3PublicACL"
        Effect = "Deny"
        Action = ["s3:PutBucketAcl", "s3:PutObjectAcl"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = ["public-read", "public-read-write", "authenticated-read"]
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
        Sid    = "ProtectIAMPasswordPolicy"
        Effect = "Deny"
        Action = [
          "iam:DeleteAccountPasswordPolicy",
          "iam:UpdateAccountPasswordPolicy"
        ]
        Resource = "*"
      },
      {
        # Identity Perimeter: 조직 외부 AWS 계정의 API 호출 차단
        Sid    = "EnforceIdentityPerimeter"
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalOrgID" = data.aws_organizations_organization.current.id
          }
          Bool = { "aws:PrincipalIsAWSService" = "false" }
        }
      }
    ]
  })
}

# ─── Security OU SCP ─────────────────────────────────────────────────────────
resource "aws_organizations_policy" "security_ou" {
  name        = "Security-OU-SCP"
  description = "Security OU: Log/Audit 보호 + 보안 서비스 삭제 차단 + 워크로드 배포 금지"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Log Archive S3 버킷 임의 변경·삭제 차단
        Sid    = "ProtectLogArchiveS3"
        Effect = "Deny"
        Action = [
          "s3:DeleteBucket",
          "s3:DeleteBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:PutEncryptionConfiguration",
          "s3:PutLifecycleConfiguration"
        ]
        Resource = "*"
      },
      {
        # Security Hub / GuardDuty / Config 비활성화·삭제 차단
        Sid    = "DenySecurityServiceDisable"
        Effect = "Deny"
        Action = [
          "guardduty:DeleteDetector",
          "guardduty:DisableOrganizationAdminAccount",
          "guardduty:DisassociateMembers",
          "guardduty:StopMonitoringMembers",
          "securityhub:DisableSecurityHub",
          "securityhub:DeleteHub",
          "securityhub:DisassociateMembers",
          "config:DeleteConfigurationRecorder",
          "config:DeleteDeliveryChannel",
          "config:StopConfigurationRecorder"
        ]
        Resource = "*"
      },
      {
        # 보안 전용 계정에 워크로드 혼재 방지 (공격 표면 확대 차단)
        Sid    = "DenyWorkloadResourceCreation"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "ecs:CreateCluster",
          "eks:CreateCluster",
          "rds:CreateDBInstance",
          "rds:CreateDBCluster",
          "elasticache:CreateCacheCluster",
          "lambda:CreateFunction"
        ]
        Resource = "*"
      }
    ]
  })
}

# ─── Infrastructure OU SCP (공통) ─────────────────────────────────────────────
resource "aws_organizations_policy" "infrastructure_ou" {
  name        = "Infrastructure-OU-SCP"
  description = "Infrastructure OU: CI/CD 경유 강제, 직접 콘솔 인프라 변경 차단"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 모든 인프라 변경은 TerraformExecutionRole 경유 강제
        Sid    = "DenyDirectConsoleInfraChange"
        Effect = "Deny"
        Action = [
          "ec2:CreateVpc", "ec2:DeleteVpc",
          "ec2:CreateSubnet", "ec2:DeleteSubnet",
          "ec2:CreateRouteTable", "ec2:DeleteRouteTable",
          "ec2:CreateInternetGateway", "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway", "ec2:DetachInternetGateway"
        ]
        Resource = "*"
        Condition = {
          StringNotLike = {
            "aws:PrincipalARN" = [
              "arn:aws:iam::*:role/TerraformExecutionRole",
              "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*/*"
            ]
          }
        }
      }
    ]
  })
}

# ─── Network 계정 SCP (계정 레벨) ────────────────────────────────────────────
resource "aws_organizations_policy" "network_account" {
  name        = "Network-Account-SCP"
  description = "Network 계정: VPC/TGW/Route53/WAF 외 서비스 생성 차단"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowNetworkServicesOnly"
        Effect = "Deny"
        NotAction = [
          "ec2:*Vpc*", "ec2:*Subnet*", "ec2:*Route*", "ec2:*Gateway*",
          "ec2:*FlowLog*", "ec2:*NetworkAcl*", "ec2:*SecurityGroup*",
          "ec2:*Address*", "ec2:*NetworkInterface*", "ec2:*TransitGateway*",
          "ec2:*VpnConnection*", "ec2:*VpnGateway*", "ec2:*CustomerGateway*",
          "ec2:*Peering*", "ec2:Describe*",
          "route53:*", "route53resolver:*",
          "network-firewall:*", "wafv2:*",
          "ram:*", "directconnect:*",
          "cloudwatch:*", "logs:*", "cloudtrail:*", "config:*",
          "iam:Get*", "iam:List*", "iam:PassRole",
          "sts:*", "support:*", "health:*",
          "ssm:*", "kms:*", "s3:*", "sns:*",
          "organizations:DescribeOrganization"
        ]
        Resource = "*"
      }
    ]
  })
}

# ─── Backup 계정 SCP (계정 레벨) ─────────────────────────────────────────────
resource "aws_organizations_policy" "backup_account" {
  name        = "Backup-Account-SCP"
  description = "Backup 계정: 백업 볼트 삭제·Lock 해제 차단, 외부 쓰기 차단"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyBackupVaultDelete"
        Effect = "Deny"
        Action = [
          "backup:DeleteBackupVault",
          "backup:DeleteBackupVaultLockConfiguration",
          "backup:DeleteBackupVaultNotifications",
          "backup:DeleteRecoveryPoint",
          "backup:UpdateRecoveryPointLifecycle"
        ]
        Resource = "*"
      },
      {
        # 조직 외부 계정의 백업 데이터 접근 차단
        Sid    = "DenyExternalBackupWrite"
        Effect = "Deny"
        Action = ["backup:CopyIntoBackupVault", "backup:ExportBackupPlanTemplate"]
        Resource = "*"
        Condition = {
          StringNotEquals = { "aws:PrincipalOrgID" = var.org_id }
          Bool            = { "aws:PrincipalIsAWSService" = "false" }
        }
      }
    ]
  })
}

# ─── Shared Services 계정 SCP (계정 레벨) ────────────────────────────────────
resource "aws_organizations_policy" "shared_services_account" {
  name        = "SharedServices-Account-SCP"
  description = "Shared Services 계정: CI/CD 경유 외 워크로드 직접 배포 차단"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDirectWorkloadDeploy"
        Effect = "Deny"
        Action = [
          "ecs:CreateService", "ecs:UpdateService",
          "eks:CreateNodegroup", "ec2:RunInstances",
          "lambda:CreateFunction", "lambda:UpdateFunctionCode"
        ]
        Resource = "*"
        Condition = {
          StringNotLike = {
            "aws:PrincipalARN" = [
              "arn:aws:iam::*:role/AppCICDRole",
              "arn:aws:iam::*:role/ImageBuilderExecutionRole",
              "arn:aws:iam::*:role/TerraformExecutionRole",
              "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*/*"
            ]
          }
        }
      }
    ]
  })
}

# ─── Production OU SCP ───────────────────────────────────────────────────────
resource "aws_organizations_policy" "production_ou" {
  name        = "Production-OU-SCP"
  description = "Production OU: 암호화 강제, IMDSv2, 태그 강제, 보안 서비스 보호, 네트워크 보호"
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
          Null = { "s3:x-amz-server-side-encryption" = "false" }
        }
      },
      {
        Sid    = "DenyUnencryptedEBS"
        Effect = "Deny"
        Action = "ec2:CreateVolume"
        Resource = "*"
        Condition = { Bool = { "ec2:Encrypted" = "false" } }
      },
      {
        Sid    = "DenyUnencryptedRDS"
        Effect = "Deny"
        Action = ["rds:CreateDBInstance", "rds:CreateDBCluster"]
        Resource = "*"
        Condition = { Bool = { "rds:StorageEncrypted" = "false" } }
      },
      {
        # IMDSv2 강제 (SSRF 위협 방지)
        Sid    = "EnforceIMDSv2"
        Effect = "Deny"
        Action = "ec2:RunInstances"
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringNotEquals = { "ec2:MetadataHttpTokens" = "required" }
        }
      },
      {
        # EC2 종료 / RDS 삭제 - TerraformExecutionRole만 허용
        Sid    = "DenyUnauthorizedResourceDeletion"
        Effect = "Deny"
        Action = [
          "ec2:TerminateInstances",
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster"
        ]
        Resource = "*"
        Condition = {
          StringNotLike = {
            "aws:PrincipalARN" = [
              "arn:aws:iam::*:role/TerraformExecutionRole",
              "arn:aws:iam::*:role/ApprovedDestructionRole"
            ]
          }
        }
      },
      {
        # 비용 배분 태그 없는 리소스 생성 차단 (거버넌스/비용 측정)
        Sid    = "RequireCostAllocationTags"
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "rds:CreateDBInstance",
          "rds:CreateDBCluster",
          "eks:CreateCluster",
          "lambda:CreateFunction",
          "elasticache:CreateCacheCluster"
        ]
        Resource = "*"
        Condition = {
          Null = {
            "aws:RequestTag/Environment" = "true"
            "aws:RequestTag/Owner"       = "true"
            "aws:RequestTag/CostCenter"  = "true"
          }
        }
      },
      {
        # VPC Flow Logs 임의 비활성화·삭제 차단 (공격자 IP/흐름 추적 보존)
        Sid    = "ProtectVPCFlowLogs"
        Effect = "Deny"
        Action = ["ec2:DeleteFlowLogs", "logs:DeleteLogGroup", "logs:DeleteLogStream"]
        Resource = "*"
      },
      {
        # Security Group 변경 - 승인된 Role만 (인/아웃바운드 임의 변경 방지)
        Sid    = "RestrictSecurityGroupChanges"
        Effect = "Deny"
        Action = [
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DeleteSecurityGroup"
        ]
        Resource = "*"
        Condition = {
          StringNotLike = {
            "aws:PrincipalARN" = [
              "arn:aws:iam::*:role/TerraformExecutionRole",
              "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/*/*"
            ]
          }
        }
      },
      {
        # 인터넷 게이트웨이 무단 생성 차단 (네트워크 보안 우회 방지)
        Sid    = "DenyInternetGatewayCreation"
        Effect = "Deny"
        Action = ["ec2:CreateInternetGateway", "ec2:AttachInternetGateway"]
        Resource = "*"
      },
      {
        # ECR Public 차단 (외부에서 내부 이미지 접근 차단)
        Sid      = "DenyECRPublicAccess"
        Effect   = "Deny"
        Action   = "ecr-public:*"
        Resource = "*"
      },
      {
        # Secrets Manager 삭제 차단
        Sid      = "ProtectSecretsManager"
        Effect   = "Deny"
        Action   = "secretsmanager:DeleteSecret"
        Resource = "*"
      }
    ]
  })
}

# ─── Staging OU SCP ──────────────────────────────────────────────────────────
resource "aws_organizations_policy" "staging_ou" {
  name        = "Staging-OU-SCP"
  description = "Staging OU: Production 수준 허용, CI/CD 경유 배포 강제"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # DB 삭제는 TerraformExecutionRole만 허용 (실수 삭제 방지)
        Sid    = "DenyUnauthorizedDBDeletion"
        Effect = "Deny"
        Action = ["rds:DeleteDBInstance", "rds:DeleteDBCluster"]
        Resource = "*"
        Condition = {
          StringNotLike = {
            "aws:PrincipalARN" = "arn:aws:iam::*:role/TerraformExecutionRole"
          }
        }
      },
      {
        # 운영 데이터와 유사한 민감 데이터 직접 조회 차단 (개발자 직접 접속 금지)
        Sid    = "DenyDirectRDSDataAccess"
        Effect = "Deny"
        Action = [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement"
        ]
        Resource = "*"
        Condition = {
          StringNotLike = {
            "aws:PrincipalARN" = "arn:aws:iam::*:role/AppCICDRole"
          }
        }
      }
    ]
  })
}

# ─── Development OU SCP ──────────────────────────────────────────────────────
resource "aws_organizations_policy" "development_ou" {
  name        = "Development-OU-SCP"
  description = "Development OU: 고비용 인스턴스·서비스 차단, RI/SP 구매 차단, 예산 한도"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 고비용 인스턴스 차단 (t계열·m5/m6i·c5/c6i 이하만 허용)
        Sid    = "DenyExpensiveInstances"
        Effect = "Deny"
        Action = "ec2:RunInstances"
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringNotLike = {
            "ec2:InstanceType" = [
              "t2.*", "t3.*", "t3a.*", "t4g.*",
              "m5.large", "m5.xlarge", "m5.2xlarge",
              "m6i.large", "m6i.xlarge", "m6i.2xlarge",
              "c5.large", "c5.xlarge", "c6i.large", "c6i.xlarge"
            ]
          }
        }
      },
      {
        # Reserved Instances / Savings Plans 구매 차단
        Sid    = "DenyRIPurchase"
        Effect = "Deny"
        Action = [
          "ec2:PurchaseReservedInstancesOffering",
          "ec2:ModifyReservedInstances",
          "savingsplans:CreateSavingsPlan"
        ]
        Resource = "*"
      },
      {
        # 고비용 네트워크 차단 (NAT Gateway 비용 발생)
        Sid      = "DenyExpensiveNetwork"
        Effect   = "Deny"
        Action   = "ec2:CreateNatGateway"
        Resource = "*"
      },
      {
        # 고비용 분석·ML 서비스 차단
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
        # Production / Management 계정 접근 차단
        Sid    = "DenyProductionAccountAccess"
        Effect = "Deny"
        Action = "sts:AssumeRole"
        Resource = [
          "arn:aws:iam::${var.prod_app_account_id}:role/*"
        ]
      }
    ]
  })
}

# ─── Sandbox OU SCP ──────────────────────────────────────────────────────────
resource "aws_organizations_policy" "sandbox_ou" {
  name        = "Sandbox-OU-SCP"
  description = "Sandbox OU: 기본 서비스 한정, 다른 OU 연결 차단, RAM 공유 금지, 지출 제한"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # 고비용 인스턴스 차단
        Sid    = "DenyExpensiveInstances"
        Effect = "Deny"
        Action = "ec2:RunInstances"
        Resource = "arn:aws:ec2:*:*:instance/*"
        Condition = {
          StringNotLike = {
            "ec2:InstanceType" = [
              "t2.*", "t3.*", "t3a.*", "t4g.*",
              "m5.large", "m6i.large"
            ]
          }
        }
      },
      {
        # TransitGateway 연결 차단 (Production과 네트워크 격리)
        Sid    = "DenyTransitGatewayConnect"
        Effect = "Deny"
        Action = [
          "ec2:CreateTransitGateway",
          "ec2:CreateTransitGatewayVpcAttachment",
          "ec2:AcceptTransitGatewayVpcAttachment",
          "ec2:AssociateTransitGatewayRouteTable"
        ]
        Resource = "*"
      },
      {
        # VPC Peering 차단 (다른 OU와 완전 격리)
        Sid    = "DenyVpcPeering"
        Effect = "Deny"
        Action = ["ec2:CreateVpcPeeringConnection", "ec2:AcceptVpcPeeringConnection"]
        Resource = "*"
      },
      {
        # RAM 리소스 공유 금지 (공격 대상 가능성 차단)
        Sid    = "DenyRAMResourceSharing"
        Effect = "Deny"
        Action = [
          "ram:CreateResourceShare",
          "ram:AssociateResourceShare",
          "ram:AcceptResourceShareInvitation"
        ]
        Resource = "*"
      },
      {
        # RI / Savings Plans 구매 차단
        Sid    = "DenyRIPurchase"
        Effect = "Deny"
        Action = [
          "ec2:PurchaseReservedInstancesOffering",
          "savingsplans:CreateSavingsPlan"
        ]
        Resource = "*"
      },
      {
        # 엔터프라이즈 전용 서비스 차단 (실험 환경 범위 초과)
        Sid    = "DenyEnterpriseOnlyServices"
        Effect = "Deny"
        Action = [
          "outposts:*", "wavelength:*",
          "robomaker:*", "braket:*", "groundstation:*"
        ]
        Resource = "*"
      }
    ]
  })
}
