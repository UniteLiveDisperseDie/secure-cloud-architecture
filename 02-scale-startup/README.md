# 02 Scale — Startup

> [!IMPORTANT]
> 이 아키텍처는 약 1천~1만명 규모의 일반 사용자와 4명의 관리자가 운영하는 환경을 기반으로 설계된 AWS 클라우드 아키텍처입니다. 

![Stage](https://img.shields.io/badge/Stage-02%20Startup-0A7E3B?style=flat-square)
![Scope](https://img.shields.io/badge/Scope-Single%20Environment-1F6FEB?style=flat-square)
![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?style=flat-square&logo=terraform&logoColor=white)
[![AWS](https://custom-icon-badges.demolab.com/badge/AWS-FF9900?style=flat-square&logo=aws&logoColor=white)](https://aws.amazon.com)

---

## 소개

<img src="../doc/images/02-scale-startup.png" align="center" alt="소규모 아키텍처">

<br>

- CloudFront를 외부 진입점으로 사용하는 단일 환경 스택
- 로그, 비밀, 접근 제어를 초기부터 포함
- 임직원 \~4명, 사용자 1천\~1만명 규모를 가정

설계 의도와 위협 시나리오 등 자세한 내용은 저희의 [GitHub Pages 문서](https://unitelivedispersedie.github.io/secure-cloud-architecture-docs/)를 참고해주세요.

---

## 아키텍처 흐름

```text
Internet
  → Route 53
  → CloudFront (WAF 연결 예정)
      → S3 (정적 파일)
      → ALB (동적 트래픽)
          → EC2 Auto Scaling (Private Subnet)
              → RDS (Private Subnet)

CloudTrail → S3 (로그) + CloudWatch Logs → SNS → Email 알림
Secrets Manager → DB 비밀 + CloudFront/ALB 공유 시크릿
```

---

## 모듈 구성

| 모듈 | 역할 |
|------|------|
| `dns` | Route 53 Zone 참조, ACM 인증서 발급 및 검증 |
| `network` | VPC, Subnet, SG, ALB, Target Group |
| `secrets` | DB 비밀 생성 및 관리 |
| `iam` | IAM User/Role/Instance Profile, Permission Boundary |
| `compute` | EC2 Launch Template + Auto Scaling |
| `database` | RDS 인스턴스 및 네트워크 연결 |
| `observability` | CloudTrail, CloudWatch, SNS 기반 알림 |
| `cdn` | CloudFront + S3 정적 오리진 + ALB 동적 오리진 |

---

## Requirements

- Terraform >= 1.5.0
- AWS CLI >= 2.0 (configured)
- Route 53에서 사용할 도메인 소유권

---

## 빠른 시작

```bash
# 1. 변수 파일 작성 (아래의 가이드 참고)
touch terraform.tfvars

# 2. 초기화
terraform -chdir=02-scale-startup init

# 3. 플랜 확인
terraform -chdir=02-scale-startup plan -var-file=terraform.tfvars -out tfplan

# 4. 배포
terraform -chdir=02-scale-startup apply tfplan
```

---

## tfvars 작성 가이드

`terraform.tfvars`를 새로 만들고 아래 항목과 같이 채워주세요.

### 공통 식별값

```hcl
project     = "myapp"       # 리소스 이름 prefix로 사용됨
environment = "dev"
region      = "ap-northeast-2"
```

### 네트워크

```hcl
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
```

### IAM 사용자

```hcl
# Terraform이 새로 생성할 IAM 사용자 이름 목록
iam_users = ["dev-user1", "dev-user2", "dev-user3", "dev-user4"]
```

> ⚠️ 생성된 IAM User는 배포 후 반드시 MFA를 등록해야 합니다.
> 평소에는 ReadOnlyAccess만 보유하고, 작업 시 AdminRole을 Assume하는 구조입니다.

### 컴퓨팅

```hcl
ami_id               = "ami-0c9c942bd7bf113a2"   # Amazon Linux 2023 (서울)
instance_type        = "t3.small"
asg_min_size         = 1
asg_max_size         = 2
asg_desired_capacity = 1
```

### 데이터베이스

```hcl
db_name              = "appdb"
db_username          = "appuser"
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20
```

> DB 비밀번호는 Secrets Manager에서 자동 생성됩니다. `tfvars`에 직접 입력하지 않습니다.

### 도메인 및 S3

```hcl
domain_name             = "example.com"
cloudfront_price_class  = "PriceClass_200"

# 버킷 이름은 전역 고유값이어야 합니다 — 뒤에 계정 ID 등을 붙이는 것을 권장합니다
s3_frontend_bucket_name = "myapp-dev-frontend-130854680916"
s3_app_bucket_name      = "myapp-dev-app-130854680916"
s3_log_bucket_name      = "myapp-dev-logs-130854680916"
```

### 운영

```hcl
alarm_email                   = "admin@example.com"
cloudwatch_log_retention_days = 14
```

---

## 전체 tfvars 예시

```hcl
project     = "myapp"
environment = "dev"
region      = "ap-northeast-2"

iam_users = ["dev-user1", "dev-user2", "dev-user3", "dev-user4"]

vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

ami_id               = "ami-0c9c942bd7bf113a2"
instance_type        = "t3.small"
asg_min_size         = 1
asg_max_size         = 2
asg_desired_capacity = 1

db_name              = "appdb"
db_username          = "appuser"
db_instance_class    = "db.t3.micro"
db_allocated_storage = 20

domain_name             = "example.com"
cloudfront_price_class  = "PriceClass_200"
s3_frontend_bucket_name = "myapp-dev-frontend-130854680916"
s3_app_bucket_name      = "myapp-dev-app-130854680916"
s3_log_bucket_name      = "myapp-dev-logs-130854680916"

alarm_email                   = "admin@example.com"
cloudwatch_log_retention_days = 14
```

---

## 배포 후 체크리스트

- [ ] SNS 구독 메일 승인 확인
- [ ] ACM 인증서 검증 완료 및 Route 53 레코드 반영 확인
- [ ] CloudFront 경유 트래픽 정상 응답 확인
- [ ] ALB DNS 직접 접근 시 `403` 반환 확인 (CloudFront 우회 차단)
- [ ] 로그 버킷 퍼블릭 차단 및 삭제 보호 상태 확인
- [ ] CloudTrail 로그가 S3, CloudWatch에 기록되는지 확인
- [ ] RDS 퍼블릭 접근 불가 상태 확인
- [ ] IAM User 각자 MFA 등록

---

## 제거

```bash
terraform -chdir=02-scale-startup destroy
```

> ⚠️ S3 버킷에 데이터가 있는 경우 자동 삭제되지 않습니다. 먼저 버킷을 비운 후 실행하세요.