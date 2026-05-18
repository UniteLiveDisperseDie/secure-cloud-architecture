output "security_ou_id" {
  description = "Security OU ID"
  value       = module.organizations.security_ou_id
}

output "infrastructure_ou_id" {
  description = "Infrastructure OU ID"
  value       = module.organizations.infrastructure_ou_id
}

output "workloads_ou_id" {
  description = "Workloads OU ID"
  value       = module.organizations.workloads_ou_id
}

output "non_production_ou_id" {
  description = "Non-Production OU ID"
  value       = module.organizations.non_production_ou_id
}

output "production_ou_id" {
  description = "Production OU ID"
  value       = module.organizations.production_ou_id
}

output "development_ou_id" {
  description = "Development OU ID"
  value       = module.organizations.development_ou_id
}

output "staging_ou_id" {
  description = "Staging OU ID"
  value       = module.organizations.staging_ou_id
}

output "sandbox_ou_id" {
  description = "Sandbox OU ID"
  value       = module.organizations.sandbox_ou_id
}
