variable "name_prefix" {
  type = string
}

variable "logging_bucket_id" {
  type = string
}

variable "logging_bucket_arn" {
  type = string
}

variable "saas_apps" {
  type = list(object({
    name                  = string
    app_type              = string
    credential_secret_arn = string
    tenant_id             = optional(string, "")
  }))
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
