variable "project" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경"
  type        = string
}

variable "tags" {
  description = "태그"
  type        = map(string)
  default     = {}
}
