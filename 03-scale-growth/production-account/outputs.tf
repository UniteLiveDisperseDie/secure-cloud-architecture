output "vpc_id" {
  value = module.network.vpc_id
}

output "alb_dns_name" {
  value = module.network.alb_dns_name
}

output "cloudfront_domain_name" {
  value = module.cdn.cloudfront_domain_name
}

output "ecr_repository_url" {
  value = module.compute.ecr_repository_url
}

output "ecs_cluster_name" {
  value = module.compute.ecs_cluster_name
}

output "rds_endpoint" {
  value     = module.database.rds_endpoint
  sensitive = true
}

output "elasticache_endpoint" {
  value     = module.database.redis_primary_endpoint
  sensitive = true
}
