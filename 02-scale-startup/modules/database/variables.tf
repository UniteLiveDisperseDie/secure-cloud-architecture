variable "environment" {
  description = "배포 환경 (dev / stg / prod)"
  type        = string
}

variable "availability_zone" {
  description = "RDS 인스턴스를 EC2 app tier와 동일한 AZ에 고정하기 위한 가용 영역"
  type        = string
}

variable "public_subnet_ids" {
  description = "ASG가 배치될 퍼블릭 서브넷 ID 목록"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "RDS가 배치될 프라이빗 서브넷 ID 목록"
  type        = list(string)
}

variable "db_security_group_ids" {
  description = "RDS에 적용할 보안 그룹 ID 목록"
  type        = list(string)
}

variable "db_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
}

variable "db_secret_id" {
  description = "Secrets Manager에 저장된 DB 비밀번호 Secret ID (security 모듈 output)"
  type        = string
}

variable "tags" {
  description = "모든 리소스에 공통으로 적용할 태그"
  type        = map(string)
  default = {
    Project   = "my-project"
    ManagedBy = "terraform"
  }
}
