output "management_ou_id" {
  description = "Management OU ID (Security + Log Archive)"
  value       = module.organizations.management_ou_id
}

output "production_ou_id" {
  description = "Production OU ID (Production + Staging)"
  value       = module.organizations.production_ou_id
}

output "dev_ou_id" {
  description = "Dev OU ID (Development + Sandbox)"
  value       = module.organizations.dev_ou_id
}

output "foundation_scp_id" {
  description = "Foundation SCP ID (루트 레벨 전 계정 공통)"
  value       = module.organizations.foundation_scp_id
}

output "organization_id" {
  description = "AWS Organizations ID"
  value       = module.organizations.organization_id
}
