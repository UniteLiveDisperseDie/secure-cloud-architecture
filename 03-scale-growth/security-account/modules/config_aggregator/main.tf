data "aws_caller_identity" "current" {}

# IAM Role for Config Aggregator
resource "aws_iam_role" "config_aggregator" {
  name = "${var.project}-config-aggregator-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "config.amazonaws.com"
      }
    }]
  })

  tags = {
    Name      = "${var.project}-config-aggregator-role"
    Project   = var.project
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "config_aggregator" {
  role       = aws_iam_role.config_aggregator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

# Organizations 수준 Config 집계´
resource "aws_config_configuration_aggregator" "organization" {
  name = "${var.project}-org-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.config_aggregator.arn
  }

  tags = {
    Name      = "${var.project}-org-config-aggregator"
    Project   = var.project
    ManagedBy = "terraform"
  }
}
