output "nlb_dns_name" {
  value = module.load_balancing.nlb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "codepipeline_name" {
  value = module.cicd.codepipeline_name
}

output "github_connection_arn" {
  value = module.cicd.github_connection_arn
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}
