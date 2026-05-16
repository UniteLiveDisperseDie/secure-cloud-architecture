output "management_ou_id" {
  value = aws_organizations_organizational_unit.management.id
}

output "production_ou_id" {
  value = aws_organizations_organizational_unit.production.id
}

output "dev_ou_id" {
  value = aws_organizations_organizational_unit.dev.id
}

output "foundation_scp_id" {
  value = aws_organizations_policy.foundation.id
}

output "management_ou_scp_id" {
  value = aws_organizations_policy.management_ou.id
}

output "production_ou_scp_id" {
  value = aws_organizations_policy.production_ou.id
}

output "dev_ou_scp_id" {
  value = aws_organizations_policy.dev_ou.id
}

output "organization_id" {
  value = data.aws_organizations_organization.current.id
}
