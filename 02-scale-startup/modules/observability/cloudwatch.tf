locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  # Extract suffix from ALB ARN
  # ARN format: arn:aws:elasticloadbalancing:region:account:loadbalancer/app/name/suffix
  alb_arn_suffix = join("/", slice(split("/", var.alb_arn), 1, 4))
}

# CloudTrail-based alarms (Metric Filter → Alarm)

# Detect root account console login
resource "aws_cloudwatch_log_metric_filter" "root_login" {
  name           = "${var.project}-${var.environment}-root-login"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ $.userIdentity.type = \"Root\" && $.eventType = \"AwsConsoleSignIn\" }"

  metric_transformation {
    name          = "RootLoginCount"
    namespace     = "${var.project}/${var.environment}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_login" {
  alarm_name          = "${var.project}-${var.environment}-root-login"
  alarm_description   = "루트 계정 콘솔 로그인 탐지. 즉시 루트 계정 비밀번호 변경 + CloudTrail 로그 확인 필요."
  namespace           = "${var.project}/${var.environment}/Security"
  metric_name         = "RootLoginCount"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = local.common_tags
}

# Detect console logins without MFA
resource "aws_cloudwatch_log_metric_filter" "no_mfa_login" {
  name           = "${var.project}-${var.environment}-no-mfa-login"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ $.eventName = \"ConsoleLogin\" && $.additionalEventData.MFAUsed != \"Yes\" && $.userIdentity.type != \"Root\" }"

  metric_transformation {
    name          = "NoMFALoginCount"
    namespace     = "${var.project}/${var.environment}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "no_mfa_login" {
  alarm_name          = "${var.project}-${var.environment}-no-mfa-login"
  alarm_description   = "MFA 없이 콘솔 로그인 탐지. 해당 IAM User MFA 등록 상태 확인 및 IAM 정책 점검 필요."
  namespace           = "${var.project}/${var.environment}/Security"
  metric_name         = "NoMFALoginCount"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = local.common_tags
}

# Detect unauthorized API calls
resource "aws_cloudwatch_log_metric_filter" "unauthorized_api" {
  name           = "${var.project}-${var.environment}-unauthorized-api"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ ($.errorCode = \"AccessDenied\") || ($.errorCode = \"AccessDeniedException\") || ($.errorCode = \"UnauthorizedOperation\") }"

  metric_transformation {
    name          = "UnauthorizedAPICount"
    namespace     = "${var.project}/${var.environment}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api" {
  alarm_name          = "${var.project}-${var.environment}-unauthorized-api"
  alarm_description   = "5분 내 비인가 API 호출 5회 이상. CloudTrail에서 어떤 IAM User/Role이 어떤 API를 호출했는지 확인 → 비정상 시 계정 즉시 비활성화."
  namespace           = "${var.project}/${var.environment}/Security"
  metric_name         = "UnauthorizedAPICount"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 5
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = local.common_tags
}

# Detect IAM user/role/credential changes
resource "aws_cloudwatch_log_metric_filter" "iam_change_identity" {
  name           = "${var.project}-${var.environment}-iam-change-identity"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ ($.eventName = CreateUser) || ($.eventName = DeleteUser) || ($.eventName = CreateRole) || ($.eventName = DeleteRole) || ($.eventName = CreateAccessKey) || ($.eventName = UpdateAccessKey) || ($.eventName = UpdateAssumeRolePolicy) || ($.eventName = PutRolePermissionsBoundary) || ($.eventName = DeleteRolePermissionsBoundary) || ($.eventName = PutUserPermissionsBoundary) || ($.eventName = DeleteUserPermissionsBoundary) }"

  metric_transformation {
    name          = "IAMChangeCount"
    namespace     = "${var.project}/${var.environment}/Security"
    value         = "1"
    default_value = "0"
  }
}

# Detect IAM policy attachment/version changes
resource "aws_cloudwatch_log_metric_filter" "iam_change_policy" {
  name           = "${var.project}-${var.environment}-iam-change-policy"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ ($.eventName = AttachUserPolicy) || ($.eventName = DetachUserPolicy) || ($.eventName = AttachRolePolicy) || ($.eventName = DetachRolePolicy) || ($.eventName = AttachGroupPolicy) || ($.eventName = DetachGroupPolicy) || ($.eventName = PutUserPolicy) || ($.eventName = PutRolePolicy) || ($.eventName = PutGroupPolicy) || ($.eventName = DeleteUserPolicy) || ($.eventName = DeleteRolePolicy) || ($.eventName = DeleteGroupPolicy) || ($.eventName = CreatePolicy) || ($.eventName = DeletePolicy) || ($.eventName = CreatePolicyVersion) || ($.eventName = DeletePolicyVersion) || ($.eventName = SetDefaultPolicyVersion) }"

  metric_transformation {
    name          = "IAMChangeCount"
    namespace     = "${var.project}/${var.environment}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "iam_change" {
  alarm_name          = "${var.project}-${var.environment}-iam-change"
  alarm_description   = "IAM 정책/유저/롤 변경 탐지. 누가 어떤 IAM 변경을 했는지 확인 → 의도치 않은 변경이면 즉시 롤백."
  namespace           = "${var.project}/${var.environment}/Security"
  metric_name         = "IAMChangeCount"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = local.common_tags
}

# Detect Security Group changes
resource "aws_cloudwatch_log_metric_filter" "sg_change" {
  name           = "${var.project}-${var.environment}-sg-change"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ ($.eventName = AuthorizeSecurityGroupIngress) || ($.eventName = AuthorizeSecurityGroupEgress) || ($.eventName = RevokeSecurityGroupIngress) || ($.eventName = RevokeSecurityGroupEgress) || ($.eventName = CreateSecurityGroup) || ($.eventName = DeleteSecurityGroup) }"

  metric_transformation {
    name          = "SGChangeCount"
    namespace     = "${var.project}/${var.environment}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "sg_change" {
  alarm_name          = "${var.project}-${var.environment}-sg-change"
  alarm_description   = "Security Group 변경 탐지. 변경된 SG Rule 확인 → 특히 0.0.0.0/0 Inbound 추가 여부 집중 확인. 의도치 않은 변경이면 즉시 롤백."
  namespace           = "${var.project}/${var.environment}/Security"
  metric_name         = "SGChangeCount"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = local.common_tags
}

# Detect S3 bucket policy/ACL changes
resource "aws_cloudwatch_log_metric_filter" "s3_policy_change" {
  name           = "${var.project}-${var.environment}-s3-policy-change"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ ($.eventName = PutBucketPolicy) || ($.eventName = DeleteBucketPolicy) || ($.eventName = PutBucketAcl) || ($.eventName = PutBucketPublicAccessBlock) }"

  metric_transformation {
    name          = "S3PolicyChangeCount"
    namespace     = "${var.project}/${var.environment}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_policy_change" {
  alarm_name          = "${var.project}-${var.environment}-s3-policy-change"
  alarm_description   = "S3 버킷 정책/ACL 변경 탐지. 변경된 버킷 정책 즉시 확인 → 특히 퍼블릭 액세스 차단 해제 여부 확인."
  namespace           = "${var.project}/${var.environment}/Security"
  metric_name         = "S3PolicyChangeCount"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = local.common_tags
}

# Detect Secrets Manager secret access/changes
resource "aws_cloudwatch_log_metric_filter" "secrets_change" {
  name           = "${var.project}-${var.environment}-secrets-change"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  pattern        = "{ ($.eventSource = \"secretsmanager.amazonaws.com\") && (($.eventName = DeleteSecret) || ($.eventName = PutSecretValue) || ($.eventName = UpdateSecret) || ($.eventName = RotateSecret)) }"

  metric_transformation {
    name          = "SecretsChangeCount"
    namespace     = "${var.project}/${var.environment}/Security"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "secrets_change" {
  alarm_name          = "${var.project}-${var.environment}-secrets-change"
  alarm_description   = "Secrets Manager 비밀 접근/변경 탐지. 누가 어떤 Secret에 접근/변경했는지 확인. EC2 Role 외 주체면 즉시 대응."
  namespace           = "${var.project}/${var.environment}/Security"
  metric_name         = "SecretsChangeCount"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = local.common_tags
}

# ALB-based alarms (CloudWatch metrics auto-collected)

# Detect ALB 4xx spike
resource "aws_cloudwatch_metric_alarm" "alb_4xx" {
  alarm_name          = "${var.project}-${var.environment}-alb-4xx"
  alarm_description   = "5분 내 ALB 4xx 100회 이상. 스캐닝/브루트포스 시도 가능성. S3 ALB Access Log에서 공격 IP 특정 후 EC2 SG에 수동 Deny 추가."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_4XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 100
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = local.common_tags
}

# Detect ALB 5xx spike
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project}-${var.environment}-alb-5xx"
  alarm_description   = "5분 내 ALB 5xx 20회 이상. App Server 장애 또는 DoS 시도 가능성. ALB Access Log에서 어떤 요청이 5xx를 유발했는지 확인."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 2
  threshold           = 20
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = local.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = local.common_tags
}

# EC2-based alarms

# Detect EC2 CPU overload (e.g., cryptojacking)
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
  alarm_name          = "${var.project}-${var.environment}-ec2-cpu"
  alarm_description   = "EC2 CPU 80% 이상 15분 지속. 크립토재킹 또는 비정상 프로세스 가능성. SSM으로 접속 후 top/ps aux 확인. 악성 프로세스 발견 시 인스턴스 격리 후 스냅샷 보존."
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3 # 3회 연속 (일시적 급증과 구분)
  threshold           = 80
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alarm.arn]
  ok_actions    = [aws_sns_topic.alarm.arn]

  tags = local.common_tags
}
