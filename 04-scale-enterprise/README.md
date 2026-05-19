# 04 Scale — Enterprise

> [!IMPORTANT]
> 이 아키텍처는 MAU 700만 규모의 서비스와 약 300명의 임직원(AWS 실접근 인원 약 70~80명)이 운영하는 환경을 기반으로 설계된 AWS 클라우드 아키텍처입니다.  
> 현재 저장소에서는 전체 워크로드 스택을 모두 구현하지 않고, **중앙 로깅 체계**와 **OU 기반 조직 구조**를 독립 모듈로 분리해 구현했습니다.

![Stage](https://img.shields.io/badge/Stage-04%20Enterprise-0A7E3B?style=flat-square)
![Scope](https://img.shields.io/badge/Scope-Logging%20%2B%20OU-1F6FEB?style=flat-square)
![Terraform](https://img.shields.io/badge/Terraform-1.5+-7B42BC?style=flat-square&logo=terraform&logoColor=white)
[![AWS](https://custom-icon-badges.demolab.com/badge/AWS-FF9900?style=flat-square&logo=aws&logoColor=white)](https://aws.amazon.com)

---

## 1. 소개

<img src="../doc/images/04-scale-enterprise.png" align="center" alt="대규모 아키텍처">

<br>

엔터프라이즈 단계에서는 단일 애플리케이션 스택보다 **조직 단위의 운영 기준**과 **감사 가능한 보안 체계**가 더 중요해집니다.

따라서 이 디렉터리에서는 모든 리소스를 하나의 Terraform 루트로 구현하기보다, 엔터프라이즈 환경에서 공통 기반으로 재사용할 수 있는 영역을 모듈로 분리했습니다.

- 중앙 로깅 및 보안 이벤트 수집
- AWS Organizations 기반 OU 구조
- SCP와 IAM Identity Center를 통한 접근 제어
- 기존 워크로드 계정에 붙일 수 있는 관찰성/거버넌스 레이어

> [!NOTE]
> 현재 구현 범위는 **로깅 모듈**과 **OU/Management Account 모듈**입니다.  
> VPC, 컴퓨팅, 데이터베이스, CDN 등 실제 워크로드 스택은 이 단계의 구현 범위에 포함하지 않았습니다.

---

## 2. 구현

현재 `04-scale-enterprise`는 아래 두 영역을 중심으로 구성되어 있습니다.

| 영역 | 디렉터리 | 설명 |
|------|----------|------|
| 로깅 | `logging-module/` | 기존 AWS 계정과 리소스에 중앙 로깅, 보안 Findings, SIEM, 알림 체계를 붙이는 모듈 |
| OU 구조 | `management-account-module/` | AWS Organizations OU, SCP, IAM Identity Center Permission Set과 계정 할당을 구성하는 모듈 |

각 모듈의 상세 변수, 배포 방법, 주의사항은 모듈 내부 README를 기준으로 작성되어 있습니다.

- [`logging-module/README.md`](./logging-module/README.md)
- [`management-account-module/README.md`](./management-account-module/README.md)

---

### 2.1. 로깅

<img src="../doc/images/04-logging-module.png" align="center" alt="대규모 로깅 모듈">

<br>

`logging-module`은 기존 운영 환경에 중앙 로깅과 보안 이벤트 수집 체계를 붙이기 위한 모듈입니다.

이 모듈은 VPC, ALB, WAF, Route53, SaaS, 온프레미스 서버 등을 새로 만드는 목적이 아니라, 이미 존재하는 리소스에서 발생하는 로그와 보안 이벤트를 한 곳으로 모으는 역할을 합니다.

주요 구현 범위는 다음과 같습니다.

| 구성 | 설명 |
|------|------|
| Central Logging S3 | 로그를 저장하는 중앙 버킷 |
| CloudTrail | 계정 API 이벤트 수집 |
| VPC Flow Logs | 기존 VPC 트래픽 로그 수집 |
| WAF / DNS Query Logs | 기존 WAF, Route53 Hosted Zone 로그 연결 |
| Security Findings | GuardDuty, Inspector, Config, Access Analyzer, Security Hub 연동 |
| OpenSearch SIEM | 수집된 로그 검색 및 분석 |
| Alerting | SNS, Slack, Jira 기반 알림 |
| SaaS / On-premise Integration | AppFabric, FluentBit, Firehose 기반 외부 로그 수집 |

자세한 사용법과 커스터마이징 포인트는 아래 문서를 참고합니다.

- [`logging-module/README.md`](./logging-module/README.md)
- [`logging-module/CUSTOMIZATION.md`](./logging-module/CUSTOMIZATION.md)

---

### 2.2. OU

<img src="../doc/images/enterprise_ou_diagram.png" align="center" alt="대규모 OU 구조">

<br>

`management-account-module`은 엔터프라이즈 멀티어카운트 환경의 조직 구조와 접근 제어를 구성하는 모듈입니다.

AWS Organizations를 기준으로 Security, Infrastructure, Workloads, Sandbox 영역을 분리하고, 각 계정과 OU에 맞는 SCP와 IAM Identity Center 권한을 적용하는 것을 목표로 합니다.

주요 구현 범위는 다음과 같습니다.

| 구성 | 설명 |
|------|------|
| OU 구조 | Security, Infrastructure, Workloads, Sandbox 등 조직 계층 구성 |
| Account Mapping | Log Archive, Audit, Security Tooling, Network, Shared Services, Backup, Production, Staging, Development, Sandbox 계정 연결 |
| SCP | OU와 계정별 보안 가드레일 적용 |
| Delegated Admin | GuardDuty, Security Hub, Inspector, Config, Access Analyzer 등 보안 서비스 위임 관리자 설정 |
| IAM Identity Center | 페르소나별 Permission Set과 계정 할당 구성 |

자세한 OU 구조, SCP 목록, Permission Set 매트릭스는 아래 문서를 참고합니다.

- [`management-account-module/README.md`](./management-account-module/README.md)

---

## Requirements

- Terraform >= 1.5.0
- AWS CLI >= 2.0 (configured)
- AWS Organizations 활성화
- IAM Identity Center 활성화
- 관리 대상 멤버 계정 ID 확보

---

## 적용 순서

```bash
# 1. OU / Management Account 구성
terraform -chdir=04-scale-enterprise/management-account-module init
terraform -chdir=04-scale-enterprise/management-account-module plan -var-file=terraform.tfvars
terraform -chdir=04-scale-enterprise/management-account-module apply

# 2. Logging Module 구성
terraform -chdir=04-scale-enterprise/logging-module init
terraform -chdir=04-scale-enterprise/logging-module plan -var-file=terraform.tfvars
terraform -chdir=04-scale-enterprise/logging-module apply
```

> [!WARNING]
> 이 단계의 Terraform은 Organizations, SCP, Identity Center, 로그 저장소처럼 조직 전체에 영향을 줄 수 있는 리소스를 다룹니다.  
> 실제 운영 계정에 적용하기 전에는 반드시 `terraform plan` 결과를 검토해야 합니다.