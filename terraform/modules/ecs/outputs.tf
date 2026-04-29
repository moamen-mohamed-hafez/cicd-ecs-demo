output "cluster_name" {
  description = "ECS cluster name — needed in GitHub Actions workflow"
  value       = aws_ecs_cluster.main.name
}

output "service_name" {
  description = "ECS service name — needed in GitHub Actions workflow"
  value       = aws_ecs_service.main.name
}

output "cluster_arn" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

output "task_definition_arn" {
  description = "Latest task definition ARN"
  value       = aws_ecs_task_definition.main.arn
}