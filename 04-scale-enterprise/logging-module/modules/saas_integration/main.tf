##############################################################################
# saas_integration
# AppFabric를 통해 SaaS 앱 감사 로그 수집 → Central Logging S3
# saas_apps 리스트에 항목 추가만 하면 연결이 자동으로 생성됩니다.
##############################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_appfabric_app_bundle" "this" {
  tags = var.tags
}

resource "aws_iam_role" "appfabric" {
  name = "${var.name_prefix}-appfabric-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "appfabric.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = data.aws_caller_identity.current.account_id }
      }
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy" "appfabric" {
  name = "s3-write"
  role = aws_iam_role.appfabric.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:PutObjectAcl"]
      Resource = "${var.logging_bucket_arn}/saas-appfabric/*"
    }]
  })
}

data "aws_secretsmanager_secret_version" "saas" {
  for_each  = { for app in var.saas_apps : app.name => app }
  secret_id = each.value.credential_secret_arn
}

resource "aws_appfabric_app_authorization" "this" {
  for_each = { for app in var.saas_apps : app.name => app }

  app_bundle_arn = aws_appfabric_app_bundle.this.arn
  app            = each.value.app_type
  auth_type      = "oauth2"

  credential {
    oauth2_credential {
      client_id     = jsondecode(data.aws_secretsmanager_secret_version.saas[each.key].secret_string)["client_id"]
      client_secret = jsondecode(data.aws_secretsmanager_secret_version.saas[each.key].secret_string)["client_secret"]
    }
  }

  tenant {
    tenant_display_name = each.value.name
    tenant_identifier   = each.value.tenant_id != "" ? each.value.tenant_id : each.value.name
  }

  tags = merge(var.tags, { SaasApp = each.value.name })
}

resource "aws_appfabric_ingestion" "this" {
  for_each = { for app in var.saas_apps : app.name => app }

  app            = each.value.app_type
  app_bundle_arn = aws_appfabric_app_bundle.this.arn
  ingestion_type = "auditLog"
  tenant_id      = aws_appfabric_app_authorization.this[each.key].tenant[0].tenant_identifier
  tags           = merge(var.tags, { SaasApp = each.value.name })
}

resource "aws_appfabric_ingestion_destination" "this" {
  for_each = { for app in var.saas_apps : app.name => app }

  app_bundle_arn = aws_appfabric_app_bundle.this.arn
  ingestion_arn  = aws_appfabric_ingestion.this[each.key].arn

  processing_configuration {
    audit_log {
      format = "json"
      schema = "raw"
    }
  }

  destination_configuration {
    audit_log {
      destination {
        s3_bucket {
          bucket_name = var.logging_bucket_id
          prefix      = "saas-appfabric/${each.value.name}/"
        }
      }
    }
  }

  tags = merge(var.tags, { SaasApp = each.value.name })
}
