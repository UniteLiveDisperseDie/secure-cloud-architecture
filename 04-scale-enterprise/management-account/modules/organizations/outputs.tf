output "security_ou_id" {
  description = "Security OU ID"
  value       = aws_organizations_organizational_unit.security.id
}

output "infrastructure_ou_id" {
  description = "Infrastructure OU ID"
  value       = aws_organizations_organizational_unit.infrastructure.id
}

output "workloads_ou_id" {
  description = "Workloads OU ID"
  value       = aws_organizations_organizational_unit.workloads.id
}

output "non_production_ou_id" {
  description = "Non-Production OU ID"
  value       = aws_organizations_organizational_unit.non_production.id
}

output "production_ou_id" {
  description = "Production OU ID"
  value       = aws_organizations_organizational_unit.production.id
}

output "development_ou_id" {
  description = "Development OU ID"
  value       = aws_organizations_organizational_unit.development.id
}

output "staging_ou_id" {
  description = "Staging OU ID"
  value       = aws_organizations_organizational_unit.staging.id
}

output "sandbox_ou_id" {
  description = "Sandbox OU ID"
  value       = aws_organizations_organizational_unit.sandbox.id
}

output "foundation_scp_id" {
  description = "Foundation SCP Policy ID"
  value       = aws_organizations_policy.foundation.id
}

output "production_scp_id" {
  description = "Production OU SCP Policy ID"
  value       = aws_organizations_policy.production_ou.id
}
