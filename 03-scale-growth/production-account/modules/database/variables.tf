variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "db_security_group_id" {
  type = string
}

variable "cache_security_group_id" {
  type = string
}

variable "rds_kms_key_arn" {
  type = string
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.medium"
}

variable "db_engine" {
  type    = string
  default = "mysql"
}

variable "db_engine_version" {
  type    = string
  default = "8.0"
}

variable "db_allocated_storage" {
  type    = number
  default = 100
}

variable "db_secret_id" {
  type = string
}

variable "cache_node_type" {
  type    = string
  default = "cache.t3.medium"
}

variable "cache_auth_token" {
  type      = string
  sensitive = true
}
