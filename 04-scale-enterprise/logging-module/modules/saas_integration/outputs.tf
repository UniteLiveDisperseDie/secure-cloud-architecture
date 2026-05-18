output "app_bundle_arn" { value = aws_appfabric_app_bundle.this.arn }
output "app_authorization_arns" { value = { for k, v in aws_appfabric_app_authorization.this : k => v.arn } }
