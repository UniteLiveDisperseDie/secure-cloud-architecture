# Network rules
resource "aws_config_config_rule" "restricted_ssh" {
  name = "restricted-ssh"
  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  name = "vpc-flow-logs-enabled"
  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "no_unrestricted_route_to_igw" {
  name = "no-unrestricted-route-to-igw"
  source {
    owner             = "AWS"
    source_identifier = "NO_UNRESTRICTED_ROUTE_TO_IGW"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "subnet_no_public_ip" {
  name = "subnet-auto-assign-public-ip-disabled"
  source {
    owner             = "AWS"
    source_identifier = "SUBNET_AUTO_ASSIGN_PUBLIC_IP_DISABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

# S3 rules
resource "aws_config_config_rule" "s3_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "s3_public_write_prohibited" {
  name = "s3-bucket-public-write-prohibited"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "s3_ssl_only" {
  name = "s3-bucket-ssl-requests-only"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "s3_default_encryption_kms" {
  name = "s3-default-encryption-kms"
  source {
    owner             = "AWS"
    source_identifier = "S3_DEFAULT_ENCRYPTION_KMS"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "s3_versioning_enabled" {
  name = "s3-bucket-versioning-enabled"
  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

# IAM rules
resource "aws_config_config_rule" "iam_root_access_key" {
  name = "iam-root-access-key-check"
  source {
    owner             = "AWS"
    source_identifier = "IAM_ROOT_ACCESS_KEY_CHECK"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "iam_user_mfa_enabled" {
  name = "iam-user-mfa-enabled"
  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_MFA_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "iam_password_policy" {
  name = "iam-password-policy"
  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }
  input_parameters = jsonencode({
    RequireUppercaseCharacters = "true"
    RequireLowercaseCharacters = "true"
    RequireSymbols             = "true"
    RequireNumbers             = "true"
    MinimumPasswordLength      = "14"
    PasswordReusePrevention    = "24"
    MaxPasswordAge             = "90"
  })
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "access_keys_rotated" {
  name = "access-keys-rotated"
  source {
    owner             = "AWS"
    source_identifier = "ACCESS_KEYS_ROTATED"
  }
  input_parameters = jsonencode({
    maxAccessKeyAge = "90"
  })
  depends_on = [aws_config_configuration_recorder_status.main]
}

# RDS rules
resource "aws_config_config_rule" "rds_public_access" {
  name = "rds-instance-public-access-check"
  source {
    owner             = "AWS"
    source_identifier = "RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "rds_storage_encrypted" {
  name = "rds-storage-encrypted"
  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "rds_multi_az" {
  name = "rds-multi-az-support"
  source {
    owner             = "AWS"
    source_identifier = "RDS_MULTI_AZ_SUPPORT"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "rds_automatic_minor_version_upgrade" {
  name = "rds-automatic-minor-version-upgrade-enabled"
  source {
    owner             = "AWS"
    source_identifier = "RDS_AUTOMATIC_MINOR_VERSION_UPGRADE_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "rds_deletion_protection" {
  name = "rds-instance-deletion-protection-enabled"
  source {
    owner             = "AWS"
    source_identifier = "RDS_INSTANCE_DELETION_PROTECTION_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

# ECS rules
resource "aws_config_config_rule" "ecs_task_definition_nonroot" {
  name = "ecs-task-definition-nonroot-user"
  source {
    owner             = "AWS"
    source_identifier = "ECS_TASK_DEFINITION_NONROOT_USER"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "ecs_task_definition_memory_limit" {
  name = "ecs-task-definition-memory-hard-limit"
  source {
    owner             = "AWS"
    source_identifier = "ECS_TASK_DEFINITION_MEMORY_HARD_LIMIT"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

# ElastiCache rules
resource "aws_config_config_rule" "elasticache_at_rest_encryption" {
  name = "elasticache-repl-grp-encrypted-at-rest"
  source {
    owner             = "AWS"
    source_identifier = "ELASTICACHE_REPL_GRP_ENCRYPTED_AT_REST"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "elasticache_in_transit_encryption" {
  name = "elasticache-repl-grp-encrypted-in-transit"
  source {
    owner             = "AWS"
    source_identifier = "ELASTICACHE_REPL_GRP_ENCRYPTED_IN_TRANSIT"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "elasticache_auto_failover" {
  name = "elasticache-repl-grp-auto-failover-enabled"
  source {
    owner             = "AWS"
    source_identifier = "ELASTICACHE_REPL_GRP_AUTO_FAILOVER_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

# ALB rules
resource "aws_config_config_rule" "alb_http_to_https" {
  name = "alb-http-to-https-redirection-check"
  source {
    owner             = "AWS"
    source_identifier = "ALB_HTTP_TO_HTTPS_REDIRECTION_CHECK"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "alb_deletion_protection" {
  name = "alb-deletion-protection-enabled"
  source {
    owner             = "AWS"
    source_identifier = "ALB_DELETION_PROTECTION_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

# CloudTrail rules
resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "cloudtrail-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "cloudtrail_log_file_validation" {
  name = "cloud-trail-log-file-validation-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "cloudtrail_s3_data_events" {
  name = "cloudtrail-s3-dataevents-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUDTRAIL_S3_DATAEVENTS_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "cloudtrail_encryption" {
  name = "cloud-trail-encryption-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "ecr_private_image_scanning" {
  name = "ecr-private-image-scanning-enabled"
  source {
    owner             = "AWS"
    source_identifier = "ECR_PRIVATE_IMAGE_SCANNING_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

# KMS rules
resource "aws_config_config_rule" "cmk_backing_key_rotation" {
  name = "cmk-backing-key-rotation-enabled"
  source {
    owner             = "AWS"
    source_identifier = "CMK_BACKING_KEY_ROTATION_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

# Secrets Manager rules
resource "aws_config_config_rule" "secretsmanager_rotation_enabled" {
  name = "secretsmanager-rotation-enabled-check"
  source {
    owner             = "AWS"
    source_identifier = "SECRETSMANAGER_ROTATION_ENABLED_CHECK"
  }
  depends_on = [aws_config_configuration_recorder_status.main]
}

resource "aws_config_config_rule" "secretsmanager_secret_unused" {
  name = "secretsmanager-secret-unused"
  source {
    owner             = "AWS"
    source_identifier = "SECRETSMANAGER_SECRET_UNUSED"
  }
  input_parameters = jsonencode({
    unusedForDays = "90"
  })
  depends_on = [aws_config_configuration_recorder_status.main]
}
