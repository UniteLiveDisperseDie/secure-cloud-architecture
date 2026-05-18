data "aws_ssoadmin_instances" "main" {}

locals {
  sso_instance_arn  = tolist(data.aws_ssoadmin_instances.main.arns)[0]
  identity_store_id = tolist(data.aws_ssoadmin_instances.main.identity_store_ids)[0]
}

# ═══════════════════════════════════════════════════════════════════════════════
# Permission Sets
# ═══════════════════════════════════════════════════════════════════════════════

# ─── Persona 1: 인프라 담당자 ─────────────────────────────────────────────────

# Network/SharedServices/Backup/Dev/Sandbox 계정용 (AdministratorAccess)
resource "aws_ssoadmin_permission_set" "infra_admin" {
  name             = "InfraAdminAccess"
  description      = "Persona1 인프라담당자: Infrastructure OU 및 Dev/Sandbox AdministratorAccess (8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "infra_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# CI/CD 우회 직접 콘솔 변경 차단 인라인 정책
resource "aws_ssoadmin_permission_set_inline_policy" "infra_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_admin.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDirectConsoleInfraChange"
        Effect = "Deny"
        Action = [
          "ec2:CreateVpc", "ec2:DeleteVpc",
          "ec2:CreateSubnet", "ec2:DeleteSubnet"
        ]
        Resource = "*"
        Condition = {
          StringNotLike = {
            "aws:PrincipalARN" = "arn:aws:iam::*:role/TerraformExecutionRole"
          }
        }
      }
    ]
  })
}

# Security/Production/Staging ReadOnly용
resource "aws_ssoadmin_permission_set" "infra_readonly" {
  name             = "InfraReadOnly"
  description      = "Persona1 인프라담당자: Security OU / Production / Staging ReadOnly (8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "infra_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Log Archive S3 DeleteObject 차단 (인라인 이중 보호)
resource "aws_ssoadmin_permission_set_inline_policy" "infra_readonly_logarchive" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.infra_readonly.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyLogArchiveS3Delete"
        Effect   = "Deny"
        Action   = ["s3:DeleteObject", "s3:DeleteObjectVersion", "s3:DeleteBucket"]
        Resource = "*"
      }
    ]
  })
}

# ─── Persona 2: 보안 담당자 ───────────────────────────────────────────────────

# Security Tooling 계정용 (AdministratorAccess + MFA 강제 + 4hr)
resource "aws_ssoadmin_permission_set" "security_tooling_admin" {
  name             = "SecurityToolingAdmin"
  description      = "Persona2 보안담당자: Security Tooling AdministratorAccess + MFA 필수 (4hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "security_tooling_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_tooling_admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# MFA 없이 접근 차단 + 위험 액션 차단 인라인 정책
resource "aws_ssoadmin_permission_set_inline_policy" "security_tooling_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_tooling_admin.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyWithoutMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice", "iam:EnableMFADevice",
          "iam:GetUser", "iam:ListMFADevices",
          "iam:ListVirtualMFADevices", "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = { "aws:MultiFactorAuthPresent" = "false" }
        }
      },
      {
        # GuardDuty / SecurityHub 삭제·비활성화 차단 (Permission Boundary 이중 보호)
        Sid    = "DenySecurityServiceDelete"
        Effect = "Deny"
        Action = [
          "guardduty:DeleteDetector",
          "guardduty:DisableOrganizationAdminAccount",
          "securityhub:DisableSecurityHub",
          "lambda:UpdateFunctionCode",
          "iam:CreateUser",
          "iam:AttachUserPolicy",
          "organizations:LeaveOrganization"
        ]
        Resource = "*"
      },
      {
        # OpenSearch 인덱스 삭제 차단
        Sid    = "DenyOpenSearchIndexDelete"
        Effect = "Deny"
        Action = ["es:DeleteIndex", "es:ESHttpDelete"]
        Resource = "*"
      }
    ]
  })
}

# Log Archive 계정용 (ReadOnly + Athena 쿼리 허용 + S3 직접 접근 차단)
resource "aws_ssoadmin_permission_set" "security_log_archive" {
  name             = "SecurityLogArchiveAccess"
  description      = "Persona2 보안담당자: Log Archive ReadOnly + Athena 쿼리 허용 (4hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "security_log_archive" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_log_archive.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_ssoadmin_permission_set_inline_policy" "security_log_archive" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_log_archive.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Athena 쿼리 허용 (S3 직접 접근 대신 Athena 경유)
        Sid    = "AllowAthenaQuery"
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryResults",
          "athena:GetQueryExecution",
          "athena:ListQueryExecutions",
          "glue:GetDatabase", "glue:GetTable", "glue:GetPartitions"
        ]
        Resource = "*"
      },
      {
        # CloudTrail LookupEvents 허용 (90일 이내)
        Sid      = "AllowCloudTrailLookup"
        Effect   = "Allow"
        Action   = "cloudtrail:LookupEvents"
        Resource = "*"
      },
      {
        # S3 직접 접근 차단 → Athena 경유만 허용
        Sid      = "DenyS3DirectAccess"
        Effect   = "Deny"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = "*"
      },
      {
        # 로그 보존 보호: 삭제·변조 차단
        Sid    = "DenyLogTampering"
        Effect = "Deny"
        Action = [
          "s3:DeleteObject", "s3:DeleteBucket",
          "cloudtrail:DeleteTrail", "cloudtrail:StopLogging",
          "kms:ScheduleKeyDeletion", "kms:DisableKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# Audit / Management / Network ReadOnly용 (보안 담당자)
resource "aws_ssoadmin_permission_set" "security_readonly" {
  name             = "SecurityReadOnly"
  description      = "Persona2 보안담당자: Management/Audit/Network ReadOnly (8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "security_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Production/Staging/Dev SecurityAudit용 (AWS 관리형)
resource "aws_ssoadmin_permission_set" "security_audit" {
  name             = "SecurityAuditAccess"
  description      = "Persona2 보안담당자: Production/Staging/Dev SecurityAudit (AWS 관리형, 8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "security_audit" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_audit.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# ─── Persona 3: 백엔드/프론트엔드 개발자 ──────────────────────────────────────

# Dev Team 계정용 (PowerUserAccess - IAM 제외)
resource "aws_ssoadmin_permission_set" "developer_power_user" {
  name             = "DeveloperPowerUser"
  description      = "Persona3 개발자: Dev Team PowerUserAccess (IAM 제외, 8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "developer_power_user" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_power_user.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

resource "aws_ssoadmin_permission_set_inline_policy" "developer_power_user" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_power_user.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Secrets Manager /dev/* prefix만 접근 허용
        Sid    = "RestrictSecretsManagerToDevPrefix"
        Effect = "Deny"
        Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
        Resource = "*"
        Condition = {
          StringNotLike = { "secretsmanager:SecretId" = "arn:aws:secretsmanager:*:*:secret:/dev/*" }
        }
      },
      {
        # RDS/DocumentDB IAM 인증 강제 (직접 비밀번호 접속 차단)
        Sid      = "DenyRDSPasswordConnect"
        Effect   = "Deny"
        Action   = "rds-db:connect"
        Resource = "*"
        Condition = {
          StringNotEquals = { "aws:RequestedRegion" = "ap-northeast-2" }
        }
      }
    ]
  })
}

# Dev Sandbox 계정용 (AdministratorAccess)
resource "aws_ssoadmin_permission_set" "developer_sandbox_admin" {
  name             = "DeveloperSandboxAdmin"
  description      = "Persona3 개발자: Dev Sandbox AdministratorAccess (8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "developer_sandbox_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_sandbox_admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Staging App ReadOnly용 (자기 서비스 로그/EKS Namespace 조회)
resource "aws_ssoadmin_permission_set" "developer_staging_readonly" {
  name             = "DeveloperStagingReadOnly"
  description      = "Persona3 개발자: Staging App ReadOnly (CloudWatch/EKS 배포 확인, 8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "developer_staging_readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer_staging_readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ─── Persona 4: 데이터 엔지니어 ───────────────────────────────────────────────

# Production Data 계정용 (S3 마스킹 버킷/MSK Consume/Redshift SELECT only)
resource "aws_ssoadmin_permission_set" "data_engineer_prod" {
  name             = "DataEngineerProdAccess"
  description      = "Persona4 데이터엔지니어: Prod Data ReadOnly (S3 마스킹 버킷/MSK Consume/Redshift SELECT, 8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_permission_set_inline_policy" "data_engineer_prod" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.data_engineer_prod.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowMaskedS3Access"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = ["arn:aws:s3:::*-masked-*", "arn:aws:s3:::*-masked-*/*"]
      },
      {
        Sid      = "DenyPIIS3Access"
        Effect   = "Deny"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = ["arn:aws:s3:::*-pii-*", "arn:aws:s3:::*-pii-*/*"]
      },
      {
        Sid    = "AllowMSKConsume"
        Effect = "Allow"
        Action = [
          "kafka:DescribeCluster", "kafka:GetBootstrapBrokers",
          "kafka:ListClusters", "kafka:DescribeTopic"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowRedshiftSelectOnly"
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult",
          "redshift:GetClusterCredentials",
          "redshift:DescribeClusters"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowKMSDecrypt"
        Effect = "Allow"
        Action = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
        Resource = "*"
        Condition = {
          StringLike = { "kms:ViaService" = "s3.*.amazonaws.com" }
        }
      },
      {
        Sid      = "DenyIAMAndNetworkChange"
        Effect   = "Deny"
        Action   = ["iam:*", "ec2:*Route*", "ec2:*Vpc*", "ec2:*SecurityGroup*"]
        Resource = "*"
      }
    ]
  })
}

# Staging Data 계정용 (커스텀 - S3/Redshift/MSK)
resource "aws_ssoadmin_permission_set" "data_engineer_staging" {
  name             = "DataEngineerStagingAccess"
  description      = "Persona4 데이터엔지니어: Staging Data (S3 읽기쓰기/Redshift SELECT-INSERT-UPDATE/MSK, 8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_permission_set_inline_policy" "data_engineer_staging" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.data_engineer_staging.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDataS3Access"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:ListBucket", "s3:DeleteObject"]
        Resource = ["arn:aws:s3:::*/data/*", "arn:aws:s3:::*-data-*", "arn:aws:s3:::*-data-*/*"]
      },
      {
        Sid    = "AllowRedshiftDML"
        Effect = "Allow"
        Action = [
          "redshift-data:ExecuteStatement",
          "redshift-data:DescribeStatement",
          "redshift-data:GetStatementResult",
          "redshift:GetClusterCredentials",
          "redshift:DescribeClusters"
        ]
        Resource = "*"
      },
      {
        # MSK Consume 읽기/쓰기 허용 (테스트 목적) - Produce 차단 (파이프라인 오염 방지)
        Sid    = "AllowMSKConsumeOnly"
        Effect = "Allow"
        Action = [
          "kafka:DescribeCluster", "kafka:GetBootstrapBrokers",
          "kafka:ListClusters", "kafka-cluster:Connect",
          "kafka-cluster:DescribeTopic", "kafka-cluster:ReadData"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowKMSDecrypt"
        Effect = "Allow"
        Action = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
        Resource = "*"
      },
      {
        Sid      = "DenyIAMAndNetworkChange"
        Effect   = "Deny"
        Action   = ["iam:*", "ec2:*Route*", "ec2:*Vpc*"]
        Resource = "*"
      }
    ]
  })
}

# Dev Team 계정용 (데이터 서비스 전체 허용)
resource "aws_ssoadmin_permission_set" "data_engineer_dev" {
  name             = "DataEngineerDevAccess"
  description      = "Persona4 데이터엔지니어: Dev Team S3/Redshift/MSK 전체 허용 (8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_permission_set_inline_policy" "data_engineer_dev" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.data_engineer_dev.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDataServices"
        Effect = "Allow"
        Action = [
          "s3:*", "redshift:*", "redshift-data:*",
          "kafka:*", "kafka-cluster:*",
          "glue:*", "athena:*",
          "kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey",
          "cloudwatch:GetMetricData", "cloudwatch:ListMetrics",
          "logs:GetLogEvents", "logs:FilterLogEvents"
        ]
        Resource = "*"
      },
      {
        Sid      = "DenyIAMAndNetworkChange"
        Effect   = "Deny"
        Action   = ["iam:*", "ec2:*Route*", "ec2:*Vpc*", "ec2:*SecurityGroup*"]
        Resource = "*"
      }
    ]
  })
}

# Dev Sandbox 계정용 (PowerUserAccess - IAM 제외)
resource "aws_ssoadmin_permission_set" "data_engineer_sandbox" {
  name             = "DataEngineerSandboxAccess"
  description      = "Persona4 데이터엔지니어: Dev Sandbox PowerUserAccess (IAM 제외, 8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "data_engineer_sandbox" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.data_engineer_sandbox.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# ─── Persona 5: SRE / On-call ─────────────────────────────────────────────────

resource "aws_ssoadmin_permission_set" "sre_access" {
  name             = "SREAccess"
  description      = "Persona5 SRE: Production ReadOnly 평상시 / JIT Write 긴급 대응 (8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "sre_access" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.sre_access.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_ssoadmin_permission_set_inline_policy" "sre_access" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.sre_access.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # CloudWatch / X-Ray / EKS 조회 + Prometheus 메트릭 쿼리 허용
        Sid    = "AllowObservabilityAccess"
        Effect = "Allow"
        Action = [
          "xray:GetTraceSummaries", "xray:GetTrace",
          "xray:BatchGetTraces", "xray:GetServiceGraph",
          "aps:QueryMetrics", "aps:ListWorkspaces",
          "eks:DescribeCluster", "eks:ListClusters",
          "eks:ListNodegroups", "eks:DescribeNodegroup",
          "ssm:DescribeInstanceInformation",
          "ssm:GetCommandInvocation"
        ]
        Resource = "*"
      },
      {
        # Security Hub Findings 상태 변경 허용 (수동 대응)
        Sid    = "AllowSecurityHubFindingUpdate"
        Effect = "Allow"
        Action = ["securityhub:UpdateFindings", "securityhub:BatchUpdateFindings"]
        Resource = "*"
      },
      {
        # RDS Aurora Read Replica 직접 접속 허용 (마스터 차단)
        Sid    = "AllowRDSReadReplicaConnect"
        Effect = "Allow"
        Action = ["rds-db:connect"]
        Resource = "arn:aws:rds-db:*:*:dbuser:*/sre-readonly-user"
      },
      {
        # ssm:StartSession은 JIT 승인 후만 (직접 세션 차단)
        Sid      = "DenySSMDirectSession"
        Effect   = "Deny"
        Action   = "ssm:StartSession"
        Resource = "*"
      }
    ]
  })
}

# ─── Persona 6: Auditor ───────────────────────────────────────────────────────

resource "aws_ssoadmin_permission_set" "auditor_access" {
  name             = "AuditorAccess"
  description      = "Persona6 Auditor: 전 계정 ReadOnly 외부 감사·컴플라이언스 (8hr)"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "auditor_access" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.auditor_access.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_ssoadmin_permission_set_inline_policy" "auditor_access" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.auditor_access.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Athena 쿼리 허용 (감사 로그 조회)
        Sid    = "AllowAthenaForAudit"
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution", "athena:GetQueryResults",
          "athena:GetQueryExecution", "athena:ListQueryExecutions",
          "glue:GetDatabase", "glue:GetTable"
        ]
        Resource = "*"
      },
      {
        # 실제 데이터 접근 차단 (구성 조회만)
        Sid      = "DenyActualDataAccess"
        Effect   = "Deny"
        Action   = ["rds-data:ExecuteStatement", "rds-db:connect", "secretsmanager:GetSecretValue"]
        Resource = "*"
      },
      {
        # IAM 변경 차단
        Sid      = "DenyIAMChanges"
        Effect   = "Deny"
        Action   = ["iam:Create*", "iam:Delete*", "iam:Update*", "iam:Attach*", "iam:Detach*"]
        Resource = "*"
      }
    ]
  })
}

# ═══════════════════════════════════════════════════════════════════════════════
# Groups (IAM Identity Center 그룹)
# ═══════════════════════════════════════════════════════════════════════════════

resource "aws_identitystore_group" "infra" {
  identity_store_id = local.identity_store_id
  display_name      = "infra-team"
  description       = "Persona1: 인프라 담당자 (약 10명, DevOps 포함)"
}

resource "aws_identitystore_group" "security" {
  identity_store_id = local.identity_store_id
  display_name      = "security-team"
  description       = "Persona2: 보안 담당자 (약 5명)"
}

resource "aws_identitystore_group" "developer" {
  identity_store_id = local.identity_store_id
  display_name      = "developer-team"
  description       = "Persona3: 백엔드/프론트엔드 개발자 (약 40명)"
}

resource "aws_identitystore_group" "data_engineer" {
  identity_store_id = local.identity_store_id
  display_name      = "data-engineer-team"
  description       = "Persona4: 데이터 엔지니어 (약 5명)"
}

resource "aws_identitystore_group" "sre" {
  identity_store_id = local.identity_store_id
  display_name      = "sre-team"
  description       = "Persona5: SRE / On-call (약 5명)"
}

resource "aws_identitystore_group" "auditor" {
  identity_store_id = local.identity_store_id
  display_name      = "auditor-team"
  description       = "Persona6: Auditor (약 2명)"
}
