variable "org_id" {
  description = "AWS Organizations Organization ID"
  type        = string
}

variable "allowed_regions" {
  description = "허용할 AWS 리전 목록"
  type        = list(string)
}

variable "log_archive_account_id" { type = string }
variable "audit_account_id" { type = string }
variable "security_tooling_account_id" { type = string }
variable "network_account_id" { type = string }
variable "shared_services_account_id" { type = string }
variable "backup_account_id" { type = string }
variable "prod_app_account_id" { type = string }
variable "staging_app_account_id" { type = string }
variable "staging_data_account_id" { type = string }
variable "dev_team_account_id" { type = string }
variable "sandbox_account_id" { type = string }
