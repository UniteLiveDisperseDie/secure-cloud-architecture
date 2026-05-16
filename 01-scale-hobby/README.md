# 01 Scale — Hobby

> [!IMPORTANT]
> 이 아키텍처는 1인 개발자가 바이브코딩(AI 생성 코드) 기반 서비스를 AWS에 배포할 때 적용할 수 있는 보안 최소 기준을 적용한 아키텍처입니다.

![Stage](https://img.shields.io/badge/Stage-01%20Hobby-0A7E3B?style=flat-square)
![Scope](https://img.shields.io/badge/Scope-Single-1F6FEB?style=flat-square)
![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?style=flat-square&logo=terraform&logoColor=white)
[![AWS](https://custom-icon-badges.demolab.com/badge/AWS-FF9900?style=flat-square&logo=aws&logoColor=white)](https://aws.amazon.com)

---

## 소개

<img src="../doc/images/01-scale-hobby.png" align="center" alt="소규모 아키텍처">

<br>

- 단일 EC2에 앱과 DB를 함께 운영하는 최소 구성 스택
- CloudFront, RDS, Auto Scaling 없이 ALB + 단일 EC2로 구성
- 개인 개발자 1명, 사용자 50명 규모를 가정

설계 의도와 위협 시나리오 등 자세한 내용은 저희의 [GitHub Pages 문서](https://unitelivedispersedie.github.io/secure-cloud-architecture-docs/)를 참고해주세요.

---

## 아키텍처 흐름

```text
Internet
  → Route 53
  → ALB (Public Subnet, HTTPS)
      → EC2 (Public Subnet, App + DB 동거)
          → S3 (앱 파일, VPC Endpoint 경유)

GitHub Actions (OIDC)
  → S3 builds/ 업로드
  → SSM Run Command → EC2 배포

EventBridge → SNS → Email 알림
```

---

## 모듈 구성

| 모듈 | 역할 |
|------|------|
| `dns` | Route 53 Zone 참조, ACM 인증서 발급 및 검증 |
| `network` | VPC, Subnet, SG, ALB, Target Group, S3 VPC Endpoint |
| `security` | IAM User, EC2 Role, GitHub Actions OIDC Role, S3 버킷 정책 |
| `compute` | EC2 인스턴스 (App + DB 동거), IMDSv2, 암호화 볼륨 |
| `observability` | EventBridge + SNS 이메일 알림 (루트 로그인 감지 포함) |

---

## Requirements

- Terraform >= 1.5.0
- AWS CLI >= 2.0 (configured)
- Route 53에서 사용할 도메인 소유권

---

## 빠른 시작

```bash
# 1. 변수 파일 작성 (아래의 가이드 참고)
touch environments/dev/terraform.tfvars

# 2. 초기화
terraform -chdir=01-scale-hobby/environments/dev init

# 3. 플랜 확인
terraform -chdir=01-scale-hobby/environments/dev plan -var-file=terraform.tfvars -out tfplan

# 4. 배포
terraform -chdir=01-scale-hobby/environments/dev apply tfplan
```

---

## tfvars 작성 가이드

`environments/dev/terraform.tfvars`를 새로 만들고 아래 항목과 같이 채워주세요.

### 공통 식별값

```hcl
project     = "myapp"
environment = "dev"
```

### 네트워크

```hcl
vpc_cidr            = "10.0.0.0/16"
availability_zone_a = "ap-northeast-2a"
availability_zone_b = "ap-northeast-2c"
public_subnet_cidr_a = "10.0.1.0/24"
public_subnet_cidr_b = "10.0.2.0/24"
```

> `public_subnet_b`는 ALB 요구사항(2개 AZ) 충족용으로만 사용되며 실제 트래픽은 없습니다.

### IAM

```hcl
iam_user_name = "myapp-admin"
github_repo   = "your-org/your-repo"   # GitHub Actions OIDC 허용 레포
```

> ⚠️ 생성된 IAM User는 배포 후 반드시 MFA를 등록해야 합니다.
> MFA 미인증 시 모든 API 호출이 Deny됩니다.

### 컴퓨팅

```hcl
instance_type = "t3.micro"
app_port      = 8080
```

### 도메인 및 S3

```hcl
domain_name        = "example.com"
s3_app_bucket_name = "myapp-dev-app-130854680916"   # 전역 고유값
```

### 운영

```hcl
alarm_email = "admin@example.com"
```

---

## 전체 tfvars 예시

```hcl
project     = "myapp"
environment = "dev"

vpc_cidr             = "10.0.0.0/16"
availability_zone_a  = "ap-northeast-2a"
availability_zone_b  = "ap-northeast-2c"
public_subnet_cidr_a = "10.0.1.0/24"
public_subnet_cidr_b = "10.0.2.0/24"

iam_user_name = "myapp-admin"
github_repo   = "your-org/your-repo"

instance_type = "t3.micro"
app_port      = 8080

domain_name        = "example.com"
s3_app_bucket_name = "myapp-dev-app-130854680916"

alarm_email = "admin@example.com"
```

---

## 배포 후 체크리스트

- [ ] SNS 구독 메일 승인 확인 (서울 + 글로벌 각각)
- [ ] ACM 인증서 검증 완료 및 Route 53 레코드 반영 확인
- [ ] ALB HTTPS 정상 응답 확인
- [ ] EC2 SSM Session Manager 접속 확인 (SSH 키 불필요)
- [ ] IAM User MFA 등록
- [ ] GitHub Actions OIDC 연동 확인 (S3 업로드 + SSM 배포)
- [ ] EC2 루트 볼륨 암호화 상태 확인
- [ ] S3 버킷 퍼블릭 차단 상태 확인

---

## 제거

```bash
terraform -chdir=01-scale-hobby/environments/dev destroy
```

> ⚠️ EC2 루트 볼륨은 `delete_on_termination = false`로 설정되어 있어 인스턴스 삭제 후에도 볼륨이 남습니다. 필요 시 수동으로 삭제하세요.
