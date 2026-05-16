variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_username" {
  type    = string
  default = "dbadmin"
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "secrets_kms_key_arn" {
  type = string
}
