variable "name_prefix" {
  type = string
}
variable "slack_webhook_url" {
  type      = string
  default   = ""
  sensitive = true
}

variable "slack_channel" {
  type    = string
  default = "#security-alerts"
}

variable "jira_url" {
  type    = string
  default = ""
}

variable "jira_api_token_secret_arn" {
  type    = string
  default = ""
}

variable "jira_project_key" {
  type    = string
  default = "SEC"
}

variable "jira_issue_type" {
  type    = string
  default = "Bug"
}

variable "tags" {
  type    = map(string)
  default = {}
}
