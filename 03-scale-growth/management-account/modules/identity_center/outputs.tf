output "sso_instance_arn" {
  value = local.sso_instance_arn
}

output "identity_store_id" {
  value = local.identity_store_id
}

output "infra_group_id" {
  value = aws_identitystore_group.infra.group_id
}

output "security_group_id" {
  value = aws_identitystore_group.security.group_id
}

output "developer_group_id" {
  value = aws_identitystore_group.developer.group_id
}
