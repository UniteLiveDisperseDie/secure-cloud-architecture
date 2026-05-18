##############################################################################
# alerting
# SNS (Operational Alerts) → Lambda → Slack
#                          → Lambda → Jira
#
# 추가로 사용된 서비스 (다이어그램에 없음):
#   - SNS Topic Subscriptions: SNS → Lambda 트리거 연결
#   - Lambda Permission: SNS가 Lambda를 호출할 수 있는 권한
#   - CloudWatch Log Groups: Lambda 로그
##############################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_sns_topic" "this" {
  name              = "${var.name_prefix}-operational-alerts"
  kms_master_key_id = "alias/aws/sns"
  tags              = var.tags
}

resource "aws_iam_role" "lambda" {
  name = "${var.name_prefix}-alerting-lambda-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ 
      Effect = "Allow", 
      Principal = { Service = "lambda.amazonaws.com" }, 
      Action = "sts:AssumeRole" }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "lambda" {
  name = "alerting"
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
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = var.jira_api_token_secret_arn != "" ? [var.jira_api_token_secret_arn] : ["arn:aws:secretsmanager:*:*:secret:${var.name_prefix}/*"]
      }
    ]
  })
}

# ── Slack Lambda ──────────────────────────────────────────────────────────────

data "archive_file" "slack" {
  type        = "zip"
  output_path = "/tmp/${var.name_prefix}-slack.zip"
  source {
    filename = "index.py"
    content  = <<-PYTHON
import os, json, urllib.request, urllib.error, logging, time

logger = logging.getLogger()
logger.setLevel(logging.INFO)

WEBHOOK = os.environ['SLACK_WEBHOOK_URL']
CHANNEL = os.environ['SLACK_CHANNEL']
COLORS  = {'CRITICAL': '#FF0000', 'HIGH': '#FF6600', 'MEDIUM': '#FFCC00', 'LOW': '#36A64F'}

def lambda_handler(event, context):
    for record in event.get('Records', []):
        msg = json.loads(record['Sns']['Message'])
        for finding in msg.get('detail', {}).get('findings', []):
            severity = finding.get('Severity', {}).get('Label', 'UNKNOWN')
            title    = finding.get('Title', 'Security Finding')
            desc     = finding.get('Description', '')
            region   = finding.get('Region', '')
            resources = [r.get('Id', '') for r in finding.get('Resources', [])]

            payload = {
                "channel": CHANNEL,
                "username": "AWS Security Hub",
                "icon_emoji": ":rotating_light:",
                "attachments": [{
                    "color": COLORS.get(severity, '#AAAAAA'),
                    "title": f"[{severity}] {title}",
                    "text": desc,
                    "fields": [
                        {"title": "Region",    "value": region,                   "short": True},
                        {"title": "Severity",  "value": severity,                 "short": True},
                        {"title": "Resources", "value": "\n".join(resources[:3]), "short": False},
                    ],
                    "footer": "AWS Security Hub",
                    "ts": int(time.time())
                }]
            }
            try:
                req = urllib.request.Request(
                    WEBHOOK,
                    data=json.dumps(payload).encode(),
                    headers={"Content-Type": "application/json"}
                )
                urllib.request.urlopen(req, timeout=10)
                logger.info(f"Slack 전송: {title}")
            except urllib.error.URLError as e:
                logger.error(f"Slack 실패: {e}")
PYTHON
  }
}

resource "aws_lambda_function" "slack" {
  count = var.slack_webhook_url != "" ? 1 : 0

  function_name    = "${var.name_prefix}-slack-alerter"
  role             = aws_iam_role.lambda.arn
  filename         = data.archive_file.slack.output_path
  source_code_hash = data.archive_file.slack.output_base64sha256
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
      SLACK_CHANNEL     = var.slack_channel
    }
  }

  tags = var.tags
}

resource "aws_sns_topic_subscription" "slack" {
  count     = var.slack_webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.this.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack[0].arn
}

resource "aws_lambda_permission" "slack" {
  count         = var.slack_webhook_url != "" ? 1 : 0
  statement_id  = "AllowSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this.arn
}

# ── Jira Lambda ───────────────────────────────────────────────────────────────

data "archive_file" "jira" {
  type        = "zip"
  output_path = "/tmp/${var.name_prefix}-jira.zip"
  source {
    filename = "index.py"
    content  = <<-PYTHON
import os, json, boto3, urllib.request, urllib.error, base64, logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

JIRA_URL    = os.environ.get('JIRA_URL', '')
PROJECT_KEY = os.environ.get('JIRA_PROJECT_KEY', 'SEC')
ISSUE_TYPE  = os.environ.get('JIRA_ISSUE_TYPE', 'Bug')
SECRET_ARN  = os.environ.get('JIRA_SECRET_ARN', '')

def get_creds():
    sm = boto3.client('secretsmanager')
    s  = sm.get_secret_value(SecretId=SECRET_ARN)
    c  = json.loads(s['SecretString'])
    return c['email'], c['api_token']

def lambda_handler(event, context):
    if not JIRA_URL or not SECRET_ARN:
        return
    for record in event.get('Records', []):
        msg = json.loads(record['Sns']['Message'])
        for finding in msg.get('detail', {}).get('findings', []):
            severity = finding.get('Severity', {}).get('Label', '')
            if severity not in ('HIGH', 'CRITICAL'):
                continue
            create_ticket(finding, severity)

def create_ticket(finding, severity):
    email, token = get_creds()
    title     = finding.get('Title', 'Security Finding')
    desc      = finding.get('Description', '')
    region    = finding.get('Region', '')
    resources = [r.get('Id', '') for r in finding.get('Resources', [])]
    remediation = finding.get('Remediation', {}).get('Recommendation', {}).get('Text', '없음')

    payload = {
        "fields": {
            "project":     {"key": PROJECT_KEY},
            "summary":     f"[{severity}] {title[:200]}",
            "description": f"*심각도:* {severity}\n*리전:* {region}\n\n*설명:*\n{desc}\n\n*리소스:*\n" + "\n".join(f"- {r}" for r in resources) + f"\n\n*권장 조치:*\n{remediation}",
            "issuetype":   {"name": ISSUE_TYPE},
            "priority":    {"name": "Highest" if severity == "CRITICAL" else "High"},
            "labels":      ["security-hub", "auto-generated", severity.lower()],
        }
    }

    auth = base64.b64encode(f"{email}:{token}".encode()).decode()
    req  = urllib.request.Request(
        f"{JIRA_URL}/rest/api/3/issue",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "Authorization": f"Basic {auth}"}
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            result = json.loads(r.read())
            logger.info(f"Jira 티켓: {result.get('key')} - {title}")
    except urllib.error.HTTPError as e:
        logger.error(f"Jira 실패: {e.code} {e.read()}")
PYTHON
  }
}

resource "aws_lambda_function" "jira" {
  count = var.jira_url != "" && var.jira_api_token_secret_arn != "" ? 1 : 0

  function_name    = "${var.name_prefix}-jira-creator"
  role             = aws_iam_role.lambda.arn
  filename         = data.archive_file.jira.output_path
  source_code_hash = data.archive_file.jira.output_base64sha256
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      JIRA_URL         = var.jira_url
      JIRA_PROJECT_KEY = var.jira_project_key
      JIRA_ISSUE_TYPE  = var.jira_issue_type
      JIRA_SECRET_ARN  = var.jira_api_token_secret_arn
    }
  }

  tags = var.tags
}

resource "aws_sns_topic_subscription" "jira" {
  count     = var.jira_url != "" && var.jira_api_token_secret_arn != "" ? 1 : 0
  topic_arn = aws_sns_topic.this.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.jira[0].arn
}

resource "aws_lambda_permission" "jira" {
  count         = var.jira_url != "" && var.jira_api_token_secret_arn != "" ? 1 : 0
  statement_id  = "AllowSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.jira[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.this.arn
}

resource "aws_cloudwatch_log_group" "lambdas" {
  for_each          = toset(["slack-alerter", "jira-creator"])
  name              = "/aws/lambda/${var.name_prefix}-${each.key}"
  retention_in_days = 14
  tags              = var.tags
}
