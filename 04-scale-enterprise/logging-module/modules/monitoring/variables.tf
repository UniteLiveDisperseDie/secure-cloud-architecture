variable "name_prefix" {
  type = string
}
variable "cloudtrail_log_group" {
  type = string
}

variable "sns_topic_arn" {
  type = string
}

variable "enable_amp" {
  type    = bool
  default = false
}

variable "grafana_workspace_id" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
