# Common
variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev / stg / prod)"
  type        = string
}

# S3 log bucket
variable "s3_log_bucket_name" {
  description = "S3 bucket name for CloudTrail and ALB log storage"
  type        = string
}

variable "s3_log_bucket_arn" {
  description = "S3 bucket ARN for CloudTrail and ALB log storage"
  type        = string
}

# CloudWatch
variable "cloudwatch_log_retention_days" {
  description = "Log retention period in days for CloudWatch"
  type        = number
  default     = 30
}

# SNS / Alarms
variable "alarm_email" {
  description = "Email address to receive CloudWatch alarm notifications"
  type        = string
}

# Values referenced from network module
variable "alb_arn" {
  description = "ARN of the Application Load Balancer (output from the network module)"
  type        = string
}

# Values referenced from compute module
variable "asg_name" {
  description = "Name of the Auto Scaling Group (output from the compute module)"
  type        = string
}
