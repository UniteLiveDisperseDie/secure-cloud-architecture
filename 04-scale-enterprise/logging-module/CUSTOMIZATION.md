# 커스터마이징 가이드

| 항목 | 수정 위치 |
|------|----------|
| 프로젝트 이름, 환경, 태그 | 변수 |
| 배포 리전 | 변수 + `modules/s3_logging/main.tf` |
| 로그 보존 기간 | 변수 |
| 로그 영구 보존 | `modules/s3_logging/main.tf` |
| KMS 암호화 | 변수 |
| VPC Flow Log 대상 | 변수 |
| WAF 교체 | 변수 |
| ALB Access Log | 별도 구현 필요 |
| Route53 Zone | 변수 |
| SaaS 서비스 | 변수 |
| 온프레미스 소스 | 변수 |
| OpenSearch 사이즈 | 변수 |
| Slack | 변수 |
| Jira | 변수 |
| AMP, Grafana | 변수 |
| Slack 채널 심각도별 분기 | `modules/alerting/main.tf` |
| Slack 메시지 포맷 | `modules/alerting/main.tf` |
| Jira 티켓 필드 추가 | `modules/alerting/main.tf` |
| Jira 티켓 생성 심각도 기준 | `modules/alerting/main.tf` |
| EventBridge 심각도 기준 | `modules/security_findings/main.tf` |
| 보안 감지 규칙 추가 | `modules/monitoring/main.tf` |
| Auto Remediation 교정 로직 | `modules/security_findings/main.tf` |
| Security Hub 표준 추가 | `modules/security_findings/main.tf` |
| OSIS 스캔 주기 | `modules/opensearch_siem/main.tf` |
| OSIS 인덱싱 경로 추가 | `modules/opensearch_siem/main.tf` |
| S3 저장 경로 변경 | 소스별 상이 (아래 표 참조) |

---

## 프로젝트 이름, 환경, 태그 (변수)

```hcl
module "logging" {
  project     = "mycompany"
  environment = "prod"

  tags = {
    Team       = "platform-security"
    CostCenter = "sec-001"
  }
}
```

`project`와 `environment`는 모든 리소스 이름의 prefix가 됩니다. 배포 후 바꾸면 리소스 전체가 재생성되므로 처음에 확정하세요.

---

## 배포 리전 (변수 + `modules/s3_logging/main.tf`)

```hcl
provider "aws" {
  region = "ap-northeast-2"  # 변경 가능
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"       # 바꾸지 마세요. Route53 DNS 로그에 고정 필요
}
```

서울 외 리전에 배포할 때는 `modules/s3_logging/main.tf`의 ELB 서비스 계정 ID도 함께 바꿔야 합니다.

```hcl
# modules/s3_logging/main.tf → ELBAccessLogs statement
principals {
  identifiers = ["arn:aws:iam::600734575887:root"]
  # ap-northeast-2: 600734575887
  # ap-northeast-1: 582318560864
  # us-east-1:      127311923021
  # us-west-2:      797873946194
  # 전체 목록: https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/enable-access-logs.html
}
```

---

## 로그 보존 기간 (변수)

```hcl
module "logging" {
  log_retention_days = 90    # Standard → Intelligent-Tiering 전환 시점
  log_glacier_days   = 365   # Glacier IR 전환 시점. 이후 3년 뒤 만료
}
```

---

## 로그 영구 보존 (`modules/s3_logging/main.tf`)

`aws_s3_bucket_lifecycle_configuration.this` 안의 `expiration` 블록을 삭제하면 만료 없이 영구 보존됩니다.

```hcl
# 이 블록 전체 삭제
expiration {
  days = var.glacier_days + (365 * 3)
}
```

---

## KMS 암호화 (변수)

기본값은 SSE-S3입니다. KMS를 쓰려면 기존 Key ARN을 넣으세요.

```hcl
module "logging" {
  kms_key_arn = "arn:aws:kms:ap-northeast-2:123456789012:key/..."
}
```

Key가 없으면 먼저 만들고 ARN을 넘깁니다.

```hcl
resource "aws_kms_key" "logging" {
  description         = "Central logging encryption"
  enable_key_rotation = true
}

module "logging" {
  kms_key_arn = aws_kms_key.logging.arn
}
```

Key Policy에 CloudTrail, GuardDuty, Firehose가 키를 쓸 수 있도록 권한을 추가해야 합니다.

---

## VPC Flow Log 대상 (변수)

```hcl
module "logging" {
  vpc_ids = [
    "vpc-0a1b2c3d",
    "vpc-0e5f6a7b",  # 추가
  ]
  # 빈 리스트면 생성하지 않습니다
}
```

---

## WAF 교체 (변수)

```hcl
module "logging" {
  waf_acl_arn = "arn:aws:wafv2:..."
  # 비우면 Firehose와 Logging Configuration을 만들지 않습니다
}
```

---

## ALB Access Log (별도 구현 필요)

`alb_arns` 변수는 있지만 현재 코드에서는 ALB Access Log를 실제로 활성화하는 리소스가 없습니다.

| 방식 | 설명 |
|------|------|
| ALB를 Terraform으로 관리 중 | 해당 `aws_lb` 리소스에 `access_logs` 블록 추가 |
| ALB가 외부에서 관리됨 | ALB 관리 모듈에서 활성화하고 이 모듈의 버킷 이름 참조 |
| 이 모듈에서 처리 | `modules/log_sources/main.tf`에 직접 구현 추가 |

버킷 이름은 `module.logging.logging_bucket_id` output으로 참조할 수 있습니다.

---

## Route53 Zone (변수)

```hcl
module "logging" {
  route53_zone_ids = [
    "Z1D633PJN98FT9",
    "Z2FDTNDATAQYW2",  # 추가
  ]
}
```

---

## SaaS 서비스 (변수)

```hcl
module "logging" {
  saas_apps = [
    {
      name                  = "github"
      app_type              = "GITHUB"
      credential_secret_arn = "arn:aws:secretsmanager:..."
      tenant_id             = ""
    },
    {
      name                  = "confluence"
      app_type              = "ATLASSIAN"
      credential_secret_arn = "arn:aws:secretsmanager:..."
      tenant_id             = "myco.atlassian.net"
    },
  ]
}
```

`app_type` 값 목록:

| SaaS | app_type | tenant_id |
|------|----------|-----------|
| GitHub | `GITHUB` | 불필요 |
| Jira, Confluence | `ATLASSIAN` | 조직 URL |
| Google Workspace | `GOOGLEWORKSPACE` | 도메인 |
| Salesforce | `SALESFORCE` | 인스턴스 URL |
| Slack | `SLACK` | Workspace ID |
| Zoom | `ZOOM` | 계정 ID |
| Dropbox | `DROPBOX` | 불필요 |
| Box | `BOX` | Enterprise ID |
| Asana | `ASANA` | 불필요 |
| Monday.com | `MONDAY` | 불필요 |

Secret 형식:

```bash
aws secretsmanager create-secret \
  --name "logging/github-oauth" \
  --secret-string '{"client_id":"...","client_secret":"..."}'
```

---

## 온프레미스 소스 (변수)

```hcl
module "logging" {
  onprem_sources = [
    {
      name        = "idc-primary"
      description = "주 IDC 서버군"
      log_prefix  = "onprem/idc-primary/"
    },
    {
      name                  = "idc-dr"
      log_prefix            = "onprem/idc-dr/"
      existing_iam_role_arn = "arn:aws:iam::..."  # 있으면 IAM User + Access Key 생성 안 함
    },
  ]
}
```

배포 후 FluentBit 설정 확인:

```bash
aws secretsmanager get-secret-value \
  --secret-id "mycompany-prod/onprem/idc-primary/fluentbit" \
  --query SecretString --output text | jq .fluentbit_output_config -r
```

---

## OpenSearch 사이즈 (변수)

```hcl
module "logging" {
  opensearch_instance_type   = "r6g.large.search"
  opensearch_instance_count  = 2
  opensearch_ebs_volume_size = 100
}
```

노드당 월 비용 참고 (ap-northeast-2):

| 타입 | 비용 | 용도 |
|------|------|------|
| `t3.small.search` | ~$15 | 개발 |
| `t3.medium.search` | ~$30 | 스테이징 |
| `r6g.large.search` | ~$87 | 운영 기본값 |
| `r6g.xlarge.search` | ~$174 | 볼륨이 많을 때 |

---

## Slack (변수)

```hcl
module "logging" {
  slack_webhook_url = "https://hooks.slack.com/services/..."
  slack_channel     = "#security-alerts"
  # 비우면 Slack Lambda를 만들지 않습니다
}
```

---

## Jira (변수)

```hcl
module "logging" {
  jira_url                  = "https://myco.atlassian.net"
  jira_api_token_secret_arn = "arn:aws:secretsmanager:..."
  jira_project_key          = "SEC"
  jira_issue_type           = "Bug"
  # jira_url을 비우면 Jira Lambda를 만들지 않습니다
}
```

Secret 형식:

```bash
aws secretsmanager create-secret \
  --name "logging/jira-token" \
  --secret-string '{"email":"sec@myco.com","api_token":"..."}'
```

---

## AMP, Grafana (변수)

```hcl
module "logging" {
  enable_amp           = true
  grafana_workspace_id = "g-xxxxxxxxxx"  # 비우면 Grafana IAM Role을 만들지 않습니다
}
```

배포 후 Remote Write URL:

```bash
terraform output amp_remote_write_url
```

---

## Slack 채널 심각도별 분기 (`modules/alerting/main.tf`)

`data "archive_file" "slack"` → Python 코드

```python
# 현재
CHANNEL = os.environ['SLACK_CHANNEL']

# 변경
CHANNEL_MAP = {
    'CRITICAL': '#security-critical',
    'HIGH':     '#security-high',
    'MEDIUM':   '#security-info',
}
channel = CHANNEL_MAP.get(severity, os.environ['SLACK_CHANNEL'])
```

---

## Slack 메시지 포맷 (`modules/alerting/main.tf`)

`data "archive_file" "slack"` → `payload` 딕셔너리

Slack Attachment(구형) 대신 Block Kit으로 교체:

```python
payload = {
    "channel": channel,
    "blocks": [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": f"[{severity}] 보안 알림"}
        },
        {
            "type": "section",
            "fields": [
                {"type": "mrkdwn", "text": f"*심각도*\n{severity}"},
                {"type": "mrkdwn", "text": f"*리전*\n{region}"},
            ]
        },
        {
            "type": "section",
            "text": {"type": "mrkdwn", "text": f"*{title}*\n{desc}"}
        },
        {
            "type": "actions",
            "elements": [{
                "type": "button",
                "text": {"type": "plain_text", "text": "Security Hub에서 보기"},
                "url": f"https://{region}.console.aws.amazon.com/securityhub/home"
            }]
        }
    ]
}
```

---

## Jira 티켓 필드 추가 (`modules/alerting/main.tf`)

`data "archive_file" "jira"` → `payload["fields"]`

```python
"fields": {
    "project":   {"key": PROJECT_KEY},
    "summary":   f"[{severity}] {title[:200]}",
    "issuetype": {"name": ISSUE_TYPE},
    "priority":  {"name": "Highest" if severity == "CRITICAL" else "High"},
    "labels":    ["security-hub", "auto-generated"],

    # 추가 예시
    "assignee":   {"accountId": "712020:xxxx"},
    "components": [{"name": "Security"}],
    "duedate": (
        datetime.now() + timedelta(days=0 if severity == "CRITICAL" else 3)
    ).strftime("%Y-%m-%d"),
}
```

`datetime` 사용 시 파일 상단에 import 추가:

```python
from datetime import datetime, timedelta
```

---

## Jira 티켓 생성 심각도 기준 (`modules/alerting/main.tf`)

`data "archive_file" "jira"` → `lambda_handler`

```python
# HIGH, CRITICAL (현재)
if severity not in ('HIGH', 'CRITICAL'):
    continue

# CRITICAL만
if severity != 'CRITICAL':
    continue

# MEDIUM까지
if severity not in ('MEDIUM', 'HIGH', 'CRITICAL'):
    continue
```

---

## EventBridge 심각도 기준 (`modules/security_findings/main.tf`)

`aws_cloudwatch_event_rule.findings` → `event_pattern`

```hcl
Severity = { Label = ["HIGH", "CRITICAL"] }            # 현재
Severity = { Label = ["MEDIUM", "HIGH", "CRITICAL"] }  # MEDIUM 추가
```

Jira Lambda는 내부에서 별도로 필터링하므로 여기서 기준을 낮춰도 Jira 티켓이 폭증하지는 않습니다. SNS 알림과 Auto Remediation Lambda도 함께 호출된다는 점은 감안하세요.

---

## 보안 감지 규칙 추가 (`modules/monitoring/main.tf`)

`locals` → `security_metric_filters`

항목 하나를 추가하면 Metric Filter와 Alarm이 자동으로 함께 생성됩니다.

```hcl
locals {
  security_metric_filters = {
    # 기존 항목 유지 후 아래 추가

    console-login-no-mfa = {
      pattern    = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") && ($.userIdentity.type = \"IAMUser\") && ($.responseElements.ConsoleLogin = \"Success\") }"
      metric     = "ConsoleLoginWithoutMFA"
      threshold  = 1
      alarm_desc = "MFA 없이 콘솔 로그인"
    }

    kms-key-deletion = {
      pattern    = "{ ($.eventSource = kms.amazonaws.com) && (($.eventName = DisableKey) || ($.eventName = ScheduleKeyDeletion)) }"
      metric     = "KMSKeyDeletionCount"
      threshold  = 1
      alarm_desc = "KMS Key 삭제 또는 비활성화"
    }
  }
}
```

---

## Auto Remediation 교정 로직 추가 (`modules/security_findings/main.tf`)

`data "archive_file" "lambda"` → Python 코드. 세 곳을 수정합니다.

**교정 함수 추가:**

```python
def remediate_rds_snapshot(resource, finding):
    rds = boto3.client('rds')
    snapshot_id = resource['Id'].split(':')[-1]
    rds.modify_db_snapshot_attribute(
        DBSnapshotIdentifier=snapshot_id,
        AttributeName='restore',
        ValuesToRemove=['all']
    )
```

**REMEDIATION_MAP에 등록:**

```python
REMEDIATION_MAP = {
    "AwsS3Bucket":         remediate_s3,
    "AwsIamAccessKey":     remediate_iam_key,
    "AwsEc2SecurityGroup": remediate_sg,
    "AwsRdsDbSnapshot":    remediate_rds_snapshot,  # 추가
}
```

**IAM Policy에 액션 추가** (`aws_iam_role_policy.lambda`):

```hcl
Action = [
  "s3:PutBucketPublicAccessBlock",
  "ec2:RevokeSecurityGroupIngress",
  "iam:UpdateAccessKey",
  "rds:ModifyDBSnapshotAttribute",  # 추가
]
```

---

## Security Hub 표준 추가 (`modules/security_findings/main.tf`)

`aws_securityhub_standards_subscription` 블록 아래에 추가:

```hcl
resource "aws_securityhub_standards_subscription" "pci_dss" {
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/pci-dss/v/3.2.1"
  depends_on    = [aws_securityhub_account.this]
}

resource "aws_securityhub_standards_subscription" "nist" {
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.name}::standards/nist-800-53/v/5.0.0"
  depends_on    = [aws_securityhub_account.this]
}
```

---

## OSIS 스캔 주기 (`modules/opensearch_siem/main.tf`)

`aws_osis_pipeline.this` → `pipeline_configuration_body` YAML

```yaml
scheduling:
  interval: PT5M   # 현재 5분. PT1M, PT30M, PT1H 등으로 변경
```

---

## OSIS 인덱싱 경로 추가 (`modules/opensearch_siem/main.tf`)

S3 경로를 새로 추가했을 때 OSIS가 스캔하도록 `include_prefix`에 넣어야 합니다.

`aws_osis_pipeline.this` → `filter.include_prefix`

```yaml
filter:
  include_prefix:
    - "cloudtrail/"
    - "guardduty/"
    - "vpc-flow-logs/"
    - "waf-logs/"
    - "config/"
    - "saas-appfabric/"
    - "onprem/"
    - "custom-logs/"   # 추가
```

`onprem/` 하위 경로는 이미 포함되므로 온프레미스 소스를 추가할 때는 별도로 넣지 않아도 됩니다.

---

## S3 저장 경로 변경

| 로그 소스 | 파일 | 리소스 | 속성 |
|----------|------|--------|------|
| CloudTrail | `modules/log_sources/main.tf` | `aws_cloudtrail.this` | `s3_key_prefix` |
| WAF | `modules/log_sources/main.tf` | `aws_kinesis_firehose_delivery_stream.waf` | `prefix` |
| VPC Flow Logs | `modules/log_sources/main.tf` | `aws_flow_log.this` | `log_destination` |
| Config | `modules/security_findings/main.tf` | `aws_config_delivery_channel.this` | `s3_key_prefix` |
| GuardDuty | `modules/security_findings/main.tf` | `aws_guardduty_publishing_destination.s3` | `destination_arn` |
| AppFabric | `modules/saas_integration/main.tf` | `aws_appfabric_ingestion_destination.this` | `s3_bucket.prefix` |
| 온프레미스 | 호출하는 `main.tf` | `onprem_sources[].log_prefix` | 변수로 제어 |

S3 경로를 바꾸면 OSIS `include_prefix`도 함께 업데이트해야 합니다.

---

## 자주 하는 실수

| 증상 | 원인 | 해결 |
|------|------|------|
| 온프레미스 소스 추가 후 OpenSearch에 데이터 없음 | OSIS `include_prefix` 누락 | `modules/opensearch_siem/main.tf`의 `include_prefix`에 경로 추가 |
| AppFabric 오류 | 리전 미지원 | AppFabric은 `us-east-1`, `ap-northeast-1` 등 일부 리전만 지원 |
| Route53 로그 생성 오류 | `aws.us_east_1` provider 미전달 | `providers = { aws.us_east_1 = aws.us_east_1 }` 추가 |
| Security Hub 충돌 | 계정에 이미 활성화됨 | `terraform import module.logging.module.security_findings.aws_securityhub_account.this $(aws sts get-caller-identity --query Account --output text)` |
| GuardDuty 충돌 | 계정에 이미 활성화됨 | `terraform import module.logging.module.security_findings.aws_guardduty_detector.this $(aws guardduty list-detectors --query 'DetectorIds[0]' --output text)` |
| S3 경로 변경 후 OSIS 재스캔 안 됨 | 파이프라인이 변경을 인식 못함 | `terraform taint module.logging.module.opensearch_siem.aws_osis_pipeline.this` 후 재배포 |
