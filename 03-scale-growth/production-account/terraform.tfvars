project     = "myproject"
environment = "prod"
region      = "ap-northeast-2"

security_account_id = "111122223333"
github_org          = "my-github-org"
github_repo         = "my-app-repo"

vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["ap-northeast-2a", "ap-northeast-2c"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
db_subnet_cidrs      = ["10.0.21.0/24", "10.0.22.0/24"]

instance_type        = "t3.medium"
asg_min_size         = 2
asg_max_size         = 8
asg_desired_capacity = 2
container_image      = "777788889999.dkr.ecr.ap-northeast-2.amazonaws.com/myproject:latest"
container_port       = 8080

db_engine          = "mysql"
db_engine_version  = "8.0"
db_instance_class  = "db.t3.medium"
db_name            = "appdb"
db_username        = "admin"
db_allocated_storage = 100
cache_node_type    = "cache.t3.medium"

domain_name             = "example.com"
cloudfront_price_class  = "PriceClass_200"
s3_frontend_bucket_name = "myproject-prod-frontend"
s3_app_bucket_name      = "myproject-prod-app"

# Log Archive Account 연동 (log-archive-account terraform output 값)
log_archive_bucket_name = "myproject-central-logs"
log_archive_bucket_arn  = "arn:aws:s3:::myproject-central-logs"
log_archive_kms_key_arn = "arn:aws:kms:ap-northeast-2:444455556666:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

alarm_email                   = "ops@example.com"
cloudwatch_log_retention_days = 90
