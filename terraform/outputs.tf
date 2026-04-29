output "alb_dns_name" {
  description = "Public DNS of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR URL — use this in GitHub Actions"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name — use in GitHub Actions"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name — use in GitHub Actions"
  value       = module.ecs.service_name
}

output "github_actions_role_arn" {
  description = "Paste this as AWS_ROLE_ARN secret in GitHub"
  value       = module.iam.github_actions_role_arn
}

output "vpc_id" {
  value = module.networking.vpc_id
}