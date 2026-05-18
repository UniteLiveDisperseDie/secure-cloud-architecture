##############################################################################
# security_findings
# Inspector / GuardDuty(Extended TD) / Access Analyzer / Config / FW Manager
# → Security Hub → EventBridge → Lambda(Auto Remediation) + SNS
##############################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ── GuardDuty (Extended Threat Detection) ────────────────────────────────────

resource "aws_guardduty_detector" "this" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = true
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }

  tags = var.tags
}

resource "aws_guardduty_publishing_destination" "s3" {
  count            = var.enable_guardduty && var.kms_key_arn != null && var.kms_key_arn != "" ? 1 : 0
  detector_id      = aws_guardduty_detector.this[0].id
  destination_arn  = "${var.logging_bucket_arn}/guardduty"
  destination_type = "S3"
  kms_key_arn      = var.kms_key_arn
}

# ── Inspector v2 ─────────────────────────────────────────────────────────────

resource "aws_inspector2_enabler" "this" {
  count          = var.enable_inspector ? 1 : 0
  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["EC2", "ECR", "LAMBDA", "LAMBDA_CODE"]
}

# ── IAM Access Analyzer ───────────────────────────────────────────────────────

resource "aws_accessanalyzer_analyzer" "this" {
  count         = var.enable_access_analyzer ? 1 : 0
  analyzer_name = "${var.name_prefix}-access-analyzer"
  type          = "ACCOUNT"
  tags          = var.tags
}

# ── AWS Config ────────────────────────────────────────────────────────────────

resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0
  name  = "${var.name_prefix}-config-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "config.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count      = var.enable_config ? 1 : 0
  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  count    = var.enable_config ? 1 : 0
  name     = "${var.name_prefix}-config-recorder"
  role_arn = aws_iam_role.config[0].arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "this" {
  count          = var.enable_config ? 1 : 0
  name           = "${var.name_prefix}-config-delivery"
  s3_bucket_name = var.logging_bucket_id
  s3_key_prefix  = "config"
  snapshot_delivery_properties { delivery_frequency = "Six_Hours" }
  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  count      = var.enable_config ? 1 : 0
  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.this]
}

# ── Security Hub ──────────────────────────────────────────────────────────────

resource "aws_securityhub_account" "this" {
  count = var.enable_security_hub ? 1 : 0
}

resource "aws_securityhub_standards_subscription" "fsbp" {
  count         = var.enable_security_hub ? 1 : 0
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.this]
}

resource "aws_securityhub_standards_subscription" "cis" {
  count         = var.enable_security_hub ? 1 : 0
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.4.0"
  depends_on    = [aws_securityhub_account.this]
}

resource "aws_securityhub_product_subscription" "guardduty" {
  count       = var.enable_security_hub && var.enable_guardduty ? 1 : 0
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/guardduty"
  depends_on  = [aws_securityhub_account.this, aws_guardduty_detector.this]
}

resource "aws_securityhub_product_subscription" "inspector" {
  count       = var.enable_security_hub && var.enable_inspector ? 1 : 0
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/inspector"
  depends_on  = [aws_securityhub_account.this, aws_inspector2_enabler.this]
}

resource "aws_securityhub_product_subscription" "config" {
  count       = var.enable_security_hub && var.enable_config ? 1 : 0
  product_arn = "arn:aws:securityhub:${data.aws_region.current.name}::product/aws/config"
  depends_on  = [aws_securityhub_account.this]
}

# ── EventBridge: Security Hub Findings → Lambda + SNS ────────────────────────

resource "aws_cloudwatch_event_rule" "findings" {
  count       = var.enable_security_hub ? 1 : 0
  name        = "${var.name_prefix}-security-hub-findings"
  description = "Security Hub HIGH/CRITICAL Findings 라우팅"

  event_pattern = jsonencode({
    source      = ["aws.securityhub"]
    detail-type = ["Security Hub Findings - Imported"]
    detail = {
      findings = {
        Severity    = { Label = ["HIGH", "CRITICAL"] }
        Workflow    = { Status = ["NEW"] }
        RecordState = ["ACTIVE"]
      }
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  count = var.enable_auto_remediation && var.enable_security_hub ? 1 : 0
  rule  = aws_cloudwatch_event_rule.findings[0].name
  arn   = aws_lambda_function.auto_remediation[0].arn
}

resource "aws_cloudwatch_event_target" "sns" {
  count = var.enable_security_hub ? 1 : 0
  rule  = aws_cloudwatch_event_rule.findings[0].name
  arn   = var.sns_topic_arn
}

# ── Lambda Auto Remediation ───────────────────────────────────────────────────

resource "aws_iam_role" "lambda" {
  name = "${var.name_prefix}-remediation-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Principal = { Service = "lambda.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "lambda" {
  name = "remediation"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["securityhub:BatchUpdateFindings"]
        Resource = "*"
      },
      {
        # 실제 자동 교정 액션
        Effect = "Allow"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSnapshot",
          "iam:UpdateAccessKey"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "/tmp/${var.name_prefix}-remediation.zip"

  source {
    filename = "index.py"
    content  = <<-PYTHON
import boto3, json, logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sh = boto3.client('securityhub')

def lambda_handler(event, context):
    findings = event.get('detail', {}).get('findings', [])
    for f in findings:
        fid = f['Id']
        for resource in f.get('Resources', []):
            rtype = resource.get('Type', '')
            try:
                if rtype == 'AwsS3Bucket':
                    remediate_s3(resource)
                elif rtype == 'AwsIamAccessKey':
                    remediate_iam_key(resource)
                elif rtype == 'AwsEc2SecurityGroup':
                    remediate_sg(resource)
                sh.batch_update_findings(
                    FindingIdentifiers=[{'Id': fid, 'ProductArn': f['ProductArn']}],
                    Workflow={'Status': 'RESOLVED'}
                )
                logger.info(f"Remediated: {fid} ({rtype})")
            except Exception as e:
                logger.error(f"Failed {fid}: {e}")

def remediate_s3(resource):
    s3 = boto3.client('s3')
    bucket = resource['Id'].split(':')[-1]
    s3.put_public_access_block(
        Bucket=bucket,
        PublicAccessBlockConfiguration={
            'BlockPublicAcls': True, 'IgnorePublicAcls': True,
            'BlockPublicPolicy': True, 'RestrictPublicBuckets': True
        }
    )

def remediate_iam_key(resource):
    iam = boto3.client('iam')
    d = resource.get('Details', {}).get('AwsIamAccessKey', {})
    if d.get('AccessKeyId') and d.get('PrincipalName'):
        iam.update_access_key(UserName=d['PrincipalName'], AccessKeyId=d['AccessKeyId'], Status='Inactive')

def remediate_sg(resource):
    ec2 = boto3.client('ec2')
    sg_id = resource['Id'].split('/')[-1]
    for port in [22, 3389]:
        try:
            ec2.revoke_security_group_ingress(
                GroupId=sg_id,
                IpPermissions=[{'IpProtocol': 'tcp', 'FromPort': port, 'ToPort': port,
                                 'IpRanges': [{'CidrIp': '0.0.0.0/0'}]}]
            )
        except Exception:
            pass
PYTHON
  }
}

resource "aws_lambda_function" "auto_remediation" {
  count            = var.enable_auto_remediation ? 1 : 0
  function_name    = "${var.name_prefix}-auto-remediation"
  role             = aws_iam_role.lambda.arn
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  timeout          = 60
  memory_size      = 256

  environment {
    variables = { LOG_LEVEL = "INFO" }
  }

  tags = var.tags
}

resource "aws_lambda_permission" "eventbridge" {
  count         = var.enable_auto_remediation ? 1 : 0
  statement_id  = "AllowEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_remediation[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.findings[0].arn
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.name_prefix}-auto-remediation"
  retention_in_days = 30
  tags              = var.tags
}
