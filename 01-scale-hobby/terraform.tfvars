project     = "hobby"
environment = "dev"
region      = "ap-northeast-2"

# 네트워크
vpc_cidr            = "10.0.0.0/16"
availability_zone_a = "ap-northeast-2a"
availability_zone_b = "ap-northeast-2c"

# EC2 / ALB
app_port = 80

# S3
s3_app_bucket_name = ""

# DNS / ACM (도메인 없으면 빈 문자열 유지)
domain_name    = ""
hosted_zone_id = ""

iam_user_name = ""
alarm_email   = ""

github_repo = ""
