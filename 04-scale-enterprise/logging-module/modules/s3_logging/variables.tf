variable "name_prefix" {
  type = string
}

variable "retention_days" {
  type    = number
  default = 90
}

variable "glacier_days" {
  type    = number
  default = 365
}

variable "kms_key_arn" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
