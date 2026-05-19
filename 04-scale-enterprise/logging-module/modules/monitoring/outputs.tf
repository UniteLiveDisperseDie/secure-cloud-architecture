output "amp_workspace_id" { value = var.enable_amp ? aws_prometheus_workspace.this[0].id : "" }
output "amp_remote_write_url" { value = var.enable_amp ? aws_prometheus_workspace.this[0].prometheus_endpoint : "" }
output "dashboard_url" {
  value = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home#dashboards:name=${aws_cloudwatch_dashboard.security.dashboard_name}"
}
